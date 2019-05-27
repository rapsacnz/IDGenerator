public without sharing class IDGenerator {

  public static String getUniqueId(Integer length, String sObjectName, String fieldName){
    return getUniqueId(length, sObjectName, fieldName,'');
  }

  public static String getUniqueId(Integer length, String sObjectName, String fieldName, String mask){

    try {

      //first a simple check:
      String idString = IdGenerator.getId(length);
      idString = IDGenerator.applyMask(idString,mask);
      String query = 'SELECT Id, ' + fieldName + ' FROM ' + sObjectName + ' WHERE ' + fieldName + ' = \'' + idString + '\'';
      sObject[] existingObjects = Database.query(query);

      //don't break out of method if running test.
      if (existingObjects.isEmpty() && !Test.isRunningTest()){
        return idString;
      }
      //else, try a few more times
      Set<String> ids = new Set<String>();
      for (Integer i = 0; i < 10; i++){
        idString = IdGenerator.getId(length);
        idString = IDGenerator.applyMask(idString,mask);
        ids.add(idString);
      }
      query = 'SELECT Id, ' + fieldName + ' FROM ' + sObjectName + ' WHERE ' + fieldName + ' IN :ids';
      System.debug(JSON.serialize(ids));

      existingObjects = Database.query(query);
      //if no matches, just take first
      if (existingObjects.isEmpty()){
        List<String> temp = new List<String>(ids);
        return temp[0];
      }
      //if less than ten found, find an id not in the returned list and return that
      String[] existingIds = new String[]{};
      for (sObject existingObject : existingObjects){
        existingIds.add((String)existingObject.get(fieldName));
      }

      ids.removeAll(existingIds);
      //if not empty, take the first
      if (!ids.isEmpty()){
        List<String> temp = new List<String>(ids);
        return temp[0];
      }
      else {
        throw new IDGeneratorException('Could not create a new Id. Please try again.');
      }
    }
    catch (Exception e){
      throw new IDGeneratorException(e.getMessage() + ' ' + e.getLineNumber() + ' ' + e.getStackTraceString());
    }

  }

  public static String getId(Integer length){
    //MICROSOFT Omits these letters and numbers: 0 1 2 5   A E I O U   L N S Z
    //leaving:
    //array of numbers:
    //[3,4,6,7,8,9]
    //array of letters:
    //['B','C','D','F','G','H','J','K','M','P','Q','R','T','V','W','X','Y']


    Map<Integer,List<String>> seeds = new Map<Integer,List<String>>{
     0=>new String[]{'3','4','6','7','8','9'},
     1=>new String[]{'B','C','D','F','G','H','J','K','M','P','Q','R','T','V','W','X','Y'}
    };
    Set<String> invalidCombinations = new Set<String>{'TH','DT','TT','KK','CK'};
    Map<String,Integer> charactersUsed = new Map<String,Integer>();

    String[] generatedString = new String[]{};
    String[] seedArray;
    Integer seedArrayLength;
    Integer elementIndex;
    for (Integer i = 0; i < length; i++){
      //Integer startWith = (Integer)(Math.random() + 1); //will be either 0 or 1 as in integer
      Integer startWith = getRandomInt(2);
      System.debug('SOLIANT STARTWITH ' + startWith);
      seedArray = seeds.get(startWith);
      Integer generatedStringLength = generatedString.size();

      Boolean valid = false;
      Integer counter = 0;
      //while (!valid && counter < 100){
      //while we haven't added anything to the array
      while (generatedStringLength == generatedString.size() && counter < 100){
        counter++;
        elementIndex = getRandomInt(seedArray.size());
        String element = seedArray[elementIndex];
        if (generatedStringLength > 0){
          String previousElement = generatedString[i - 1];
          if (!invalidCombinations.contains(previousElement + element)){
            generatedString.add(element);
          }
        }
        else {
          generatedString.add(element);
        }
      }
    }
    return String.join(generatedString,'');
  }

  private static Integer getRandomInt(Integer max) {
    return (Integer)Math.floor(Math.random() * Math.floor(max));
  }
  public static String applyMask(String idString, String mask){
    if (String.isBlank(mask)){
      return idString;
    }
    Pattern nonAlphanumeric = Pattern.compile('[^a-zA-Z0-9]');
    Matcher matcher = nonAlphanumeric.matcher(mask);
    String maskCheck = matcher.replaceAll('');

    String result = mask.replaceAll('X', '_');
    if (maskCheck.length() != idString.length()){
      throw new IDGeneratorException('Mask characters should be in format XX-XX... and masked characters should match length parameter');
    }
    else {

      String regExp = '_';
      String[] idChars = idString.split('');
      for (String idChar : idChars){
        result = result.replaceFirst(regExp, idChar);
        System.debug('SOLIANT RESULT: ' + result + '  IDCHAR ' + idChar);
      }
    }
    return result;
  }

  public class IDGeneratorException extends Exception {}
}
