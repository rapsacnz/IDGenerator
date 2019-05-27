<h2>A Quick, Simple, Clean Id Generator</h2>
Of course, you could use the built in auto-number system that Salesforce provides. You could even just use a Salesforce Id - you know it's going to be unique.
However, you might just need a number with with a unique format, formatted in a certain way eg XX-XXX-XXXX, that is not going to come back and bite you with some rude letter combination.

Noone wants an Id like 12-BIG-BUTT. 

<h4>Highlevel</h4>
My approach is pretty simple and since it's tied to querying Salesforce for prior ids may not work for everyone.

My uniqueness approach is thus:

<ol>
<li>Generate an Id (details below).</li>
<li>Look for it in Salesforce. If not found, return it.</li>
<li>Generate X (in my case 10) Ids (this is quick).</li>
<li>Look for all 10 at once in Salesforce (better to look for all in one query than one by one).</li>
<li>If there are less than 10 matches get the non matched Ids and return one of them.</li>
<li>Else, generate an error! Perhaps your Id length is too short (and hence not unique enough)!</li>
</ol>

<h4>Details</h4>
So, the inner workings of generating one of these ids are, again a little tricky.

<strong>Why</strong>? Formatting and making the Id clean can be fiddly!

There are lots of tricky and code intensive ways to try to detect if a word is bad or not... but in English(and probably other languages), this is pretty hard.
An easier approach is just to remove the ingredients that would allow the construction of a word at all.

First, we want to mix up letters and numbers - this makes it a LOT harder to construct a word!
Next, we remove numbers that look like letters and letters that are commonly involved in making words.

This is what remains - and it must be a good list, because these are the letters and numbers that you are allowed when entering serial numbers for Microsoft products.
So while I can't find any Official documentation about this, it's clear Microsoft use the same list.
Finally, we also remove a few outliers that might still conceivably still make words:
<ul class="bullet-list">
  <li>The numbers: '3','4','6','7','8','9'</li>
  <li>The letters: 'B','C','D','F','G','H','J','K','M','P','Q','R','T','V','W','X','Y'</li>
  <li>The letter combos: 'TH','DT','TT','KK','CK'</li>
</ul>


From here, we just randomly pick letters and numbers from the lists above, excluding any of the combos.
This is just a matter of getting random integers in the right range (code shown here)

```
public static String getId(Integer length){
  //MICROSOFT Omits these letters and numbers: 0 1 2 5   A E I O U   L N S Z
  //leaving: 
  //array of numbers: [3,4,6,7,8,9]
  //array of letters: ['B','C','D','F','G','H','J','K','M','P','Q','R','T','V','W','X','Y']

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
    
    Integer startWith = getRandomInt(2);
    
    seedArray = seeds.get(startWith);
    Integer generatedStringLength = generatedString.size();
    Boolean valid = false;
    Integer counter = 0;
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
```

At this point, we have a nice Id, un-masked.

To mask it, we use a little bit of regex and a loop. There are probably lots of ways of doing this, but this is a pretty simple one.
```
  //this is the essence of the mask routine (look at my github for more details)
  String result = mask.replaceAll('X', '_');
  String regExp = '_';
  String[] idChars = idString.split('');
  //loop through id and and replace all placeholder chars
  for (String idChar : idChars){
    result = result.replaceFirst(regExp, idChar);
  }
```
Hence a mask of 'XX-XXX-XXXX' becomes '3B-4C9-G8J6' for example.

Then, we return this nicely masked, generated Id back to the top routine, where it is compared against other Ids in the database.

No Problemo!!




