---
layout: post
title: Hadoop Pig
categories: [section]
navigation:
  section: [1, 5]
---
{% objective %}
- Learn how to work with Pig interactive shell.
- Understand Pig Latin data types and Pig relations.
- Can implement data processing scripts in Pig Latin.
- Can write user defined function(UDF).
{% endobjective %}

The goal of this module is to show how to construct feature vectors from the [raw event sequences data]({{ site.baseurl }}/data/) through [Hadoop Pig](http://pig.apache.org/), a high-level data processing tool on top of Hadoop MapReduce. Instead of writing Java program, you will write high level script Pig Latin and let the framework tranlsate it into Map Reduce jobs for you. 

Througout the training, you will learn how to run interactive shell and run the Pig script. We will first show basic knowledge of Pig in terms of _interactive shell_ and _data type_, then show how to complete the feature construction task step by step. The high-level process of feature construction is depicted below
![feature construction high level]({{ site.baseurl }}/image/post/hadoop-pig-process.svg "Feature Construction Process")
# Interactive Shell
Pig provides a shell to manipulate data interactively. Let's start a shell and run that in local mode for demo purpose
``` bash
> cd bigdata-bootcamp/sample/pig
> pig -x local
```
and you will see promte as
``` pig
[info] ...
grunt>  
```

Next, you can input Pig Latin **statement**, the basic construct of using Pig. For example,
``` pig
grunt> case_events = LOAD 'data/case.csv' USING PigStorage(',') AS (patientid:chararray, eventname:chararray, dateoffset:int, value:double);
```
Here we call the `case_events` a [**relation**](http://pig.apache.org/docs/r0.14.0/basic.html#relations) in Pig Latin. In this statement, we load data from `data/case.csv` file into `case_events` relation. We also specified the [**schema**](http://pig.apache.org/docs/r0.14.0/basic.html#schemas) of the data as 
```
(patientid:chararray, eventname:chararray, dateoffset:int, value:double)
```
which define a four-field tuple with names and type of each field corresponds to our raw data. Here we use the `PigStorage`, the most common adapter in Pig to load/save data from/into file system (including HDFS). Of course you can load data from other source like database using other `Storage` interface.

You can check the schema using `DESCRIBE` operator
``` pig
grunt> DESCRIBE case_events;
case_events: {patientid: chararray,eventname: chararray,dateoffset: int,value: double}
```
and collect display data with `DUMP`
```pig
grunt> DUMP case_events;
...
(021FB39310BC3797,DRUG67544054730,1352,30.0)
(021FB39310BC3797,DRUG00002021008,1391,10.0)
(021FB39310BC3797,DRUG63304073705,1393,30.0)
(021FB39310BC3797,DRUG36987235901,1456,30.0)
(021FB39310BC3797,DRUG55154239805,1456,10.0)
```
{% msgwarning %}
#### Limit Output
Sometimes, `DUMP` with generate a lot of output but you may just want to see few examples. Pig it self doesn't have operator like _head_, instead you can
```pig
tmp = LIMIT A 10;
DUMP tmpl
```
to print top 10 items in relation `A`.
{% endmsgwarning %}

{% msginfo %}
#### About Lazy Evaluation
Pig will not run immediately after you input a statement. Only when you need to `save` or `dump`, Pig will actually run. The good part of this property is that internally Pig can be optimized. A potential problem is that you may not realize you made a mistake until later statement that has output. If you are not sure, on small data set, you can `dump` frequently.
{% endmsginfo %}

The shell also provide other commands. Important ones include but not limited to

1. `fs`: serve same purpose as `hdfs dfs`, so that your can type `fs -ls` directly in pig shell instead of `hdfs dfs -ls`.
2. `pwd`: check present working directory in case file is not found.

type `help` to learn more about these commands in pig shell. Pig operators covered in later example are listed in below table, please refer to [Pig Offical Document](https://pig.apache.org/docs/r0.11.1/basic.html#Relational+Operators) to learn more.

| Operator  | Explaination |
| :------------- | :------------- |
| DISTINCT  | Removes duplicate tuples in a relation  |
| FILTER | Selects tuples from a relation based on some condition|
|FOREACH|Generates data transformations based on columns of data|
|GROUP| Groups the data in one or more relations|
| JOIN (inner)| Performs an inner join of two or more relations based on common field values| 
|LIMIT | Limits the number of output tuples|
|LOAD| Loads data from the file system|
|ORDER BY| Sorts a relation based on one or more fields|
|RANK| Returns each tuple with the rank within a relation|
|SPLIT| Partitions a relation into two or more relations|
|STORE|Stores or saves results to the file system|
|UNION| Computes the union of two or more relations, does not eliminate duplicate tuples|
|REGISTER |Registers a JAR file so that the UDFs in the file can be used|
Finally, type `quit` to leave the shell.

# Data type
In this section, we briefly describe data types. Pig can work with simple type like `int`, `double`. More important types are `tupe` and `bag`.

**Tuple** is usually represented with `()`, for example
```
(021FB39310BC3797,DRUG55154239805,1456,10.0)
```
In Pig Latin, we can either fetch field by index (like `$0`) or by name (like `patientid`). With index we can also fetch a range of fields. For example `$2..` means _2_-st to last.

**Bag** is usually denoted with `{}`, from result of `DESCRIBE case_events` we can see `case_events` itself is a bag. You can regard bag as a special unordered `set` that doesn't check duplication.

Check out the [official documentation about data type](http://pig.apache.org/docs/r0.14.0/basic.html#Data+Types+and+More) for more. You will find examples of the type in below samples, pay attention to result of `DESCRIBE` and you will find types and names of fields.

# Feature construction
Next, you will learn by practicing in the context of feature construction for predictive modeling. You will learn built-in operators like `GROUP BY`, `JOIN` as well as User Defined Function (UDF) in python. The result of feature construction will be feature matrix that can be consumed by a lot of machine learning packages.

## Overview
Feature construction works by like below figure, where sample data format of each step is depicted.
![feature construction]({{ site.baseurl }}/image/post/hadoop-pig-overview.jpg "Feature Construction Process")

We will start from loading raw data. Then we extrat the prediction target(i.e. the patient will have heart failure or not). Next, we filter and aggregate events of patient into features. After that we need to link prediction target and features to compose complete training/testing samples. Finally we split the data into training and testing sets and save.

## Load data
First, make sure you are in `bigdata-bootcamp/sample/pig` folder and ou can check availability of raw data file by
``` pig
grunt> pwd
file:/path/to/bigdata-bootcamp/sample/pig
grunt> ls data
file:/path/to/bigdata-bootcamp/sample/pig/data/case.csv<r 1>    536404
file:/path/to/bigdata-bootcamp/sample/pig/data/control.csv<r 1> 672568
grunt> 
```
Then, let's load the data as a `relation`
```
grunt> events = LOAD 'data/' USING PigStorage(',') AS (patientid:chararray, eventname:chararray, dateoffset:int, value:int);
```

## Extract target and filter
Our data set can be used for predicting heart failure (HF), and we want to predict heart failure one year before it happen. As a result, we need to find the heart failure event date (for case patient, event value is 1 means HF happened, for control patient value is 0 as there's no HF) and filter out events that happened within one year to HF. 
![Prediction Window]({{ site.baseurl }}/image/post/prediction-window.jpg "Prediction Window")
As illustrated in above figure, we will need to find HF diagnostic date and use that date to filter out events witin prediction window only.

``` pig
grunt> targets = FILTER events BY eventname == 'heartfailure';
grunt> event_target_pairs = JOIN events BY patientid, targets BY patientid;
grunt> filtered_events = FILTER event_target_pairs BY (events::dateoffset <= targets::dateoffset - 365);
```
After `JOIN` we have some redundant fields we will no longer need, so that we can project `filtered_events` into a simpler format.
```pig
grunt> filtered_events = FOREACH filtered_events GENERATE $0 AS patientid, $1 AS eventname, $3 AS value;
```
Notice that as dateoffset is no longer useful after filtering, we droped that.

## Aggregate events into feature
### Illustrative sample
Our raw data is event sequence. In order to aggregate that into feature suitable for machine learning, we can **sum** up event value as feature value corresponds to the given event. Each event type will become a feature and we will redictly use event name as feature name. For example, given below raw event sequence for a patient

```
FBFD014814507B5C,PAYMENT,1220,30.0
FBFD014814507B5C,DIAGE887,1321,1.0
FBFD014814507B5C,PAYMENT,1321,1000.0
FBFD014814507B5C,DIAGE887,907,1.0
FBFD014814507B5C,DRUG52959072214,1016,30.0
```

We can get feature name value pair for this patient with ID `FBFD014814507B5C` as
```
(PAYMENT, 1030.0)
(DIAGE887, 2.0)
(DRUG52959072214, 30.0)
```
### Code
Below code will aggregate `filtered_events` from [previous filter step](#extract-target-and-filter) into tuples in `(patientid, feature name, feature value)` format
``` pig
grunt> feature_name_values = GROUP filtered_events BY (patientid, eventname);
grunt> DESCRIBE feature_name_values;                                         
feature_name_values: {group: (patientid: chararray,eventname: chararray),filtered_events: {(patientid: chararray,eventname: chararray,value: int)}}
grunt> feature_name_values = FOREACH feature_name_values GENERATE group.$0, group.$1 as featurename, SUM(filtered_events.value) AS value;
grunt> DESCRIBE feature_name_values                                                                              
feature_name_values: {patientid: chararray,featurename: chararray,value: long}
grunt> DUMP feature_name_values;
...
(FBFD014814507B5C,DIAG38845,1)
(FBFD014814507B5C,DIAGV6546,1)
(FBFD014814507B5C,DRUG00008251302,30)
(FBFD014814507B5C,DRUG52959072214,30)
```

## Assign integer-ID to feature
### Get unique feature-ID
In machine learning setting, we want to assign an index to each different feature rather than directly use name. Form example, DIAG38845 corresponds to feature-id=1 and DIAGV6546 corresponds to feature-id=2.

Below code find unique feature name using `DISTINCT` operator and assign an index to feature name with `RANK` operator

``` pig
grunt> feature_names = FOREACH feature_name_values GENERATE featurename;
grunt> feature_names = DISTINCT feature_names;
grunt> feature_name_index = RANK feature_names;
grunt> feature_name_index = FOREACH feature_name_index GENERATE $0 AS index, $1;
grunt> DESCRIBE feature_name_index 
feature_name_index: {index: long,featurename: chararray}
grunt> DUMP feature_name_index;
...
(9973,DRUG81306041113)
(9974,DRUG91899051572)
(9975,DRUG99207049110)
(9976,DRUG99207049211)
(9977,DRUG99207049905)
(9978,DRUG99207074501)
```

### Use unique index
Next, we can update `feature_name_values` to use feature index rather than feature name.
```pig
grunt> feature_id_values = JOIN feature_name_values BY featurename, feature_name_index BY featurename;
grunt> DESCRIBE feature_id_values;
feature_id_values: {feature_name_values::patientid: chararray,feature_name_values::featurename: chararray,feature_name_values::value: long,feature_name_index::index: long,feature_name_index::featurename: chararray}  
grunt> feature_id_values = FOREACH feature_id_values GENERATE feature_name_values::patientid AS patientid, feature_name_index::index AS featureid, feature_name_values::value AS value; 
grunt> DESCRIBE feature_id_values;
feature_id_values: {patientid: chararray,featureid: long,value: long}
grunt> DUMP feature_id_values;
....
(2363A06EF118B098,9974,60)
(524F2DD2CC093F4D,9975,30)
(DB85757793B65DA0,9976,60)
(06E460A01C6DCC41,9977,10)
(276D7F6B824964C3,9978,90)
```

## Format feature matrix
### Illustratative example
Now, we are approaching the final step. We need to create a feature vector for each patient. Our ultimate result will convert each patient into a feature vector associated with target we want to predict. We already get target in the `targets` relation. Our final representation is like below
```
target featureid:value[featureid:value]...
```

For example, given patient `2363A06EF118B098` with below features and don't have heart failure (target value is 0)
```
(2363A06EF118B098,1,60)
(2363A06EF118B098,4,30)
(2363A06EF118B098,9,60)
(2363A06EF118B098,23,10)
(2363A06EF118B098,45,90)
```
we will encode the patient features as
```
0 1:60 4:30 9:60 23:10 45:90
```
notice that the `feautreid` is in increase order and this is required by a lot of machine learning package. We call such target (aka label) and features pair a `sample`.

### Code
Let's group `feature_id_values` by patientid and check the structure
```
grunt> grpd = GROUP feature_id_values BY patientid;
grunt> DESCRIBE grpd;
grpd: {group: chararray,feature_id_values: {(patientid: chararray,featureid: long,value: long)}}
```
We can find `feature_id_values` is a bag and we want to convert it into a string like `1:60 4:30 9:60 23:10 45:90` mentioned above. Here we will employ UDF defined in `utils.py` as
```python
@outputSchema("feature:chararray")
def bag_to_svmlight(input):
    return ' '.join(( "%s:%f" % (fid, float(fvalue)) for _, fid, fvalue in input))
```
The script simply enumerate all tuples from `input` and form id value pairs then join. `@outputSchema("feature:chararray")` specifies the return value name and tupe. In order to use that, we need to register it first
```pig
grunt> REGISTER utils.py USING jython AS utils;
grunt> feature_vectors = FOREACH grpd {
    sorted = ORDER feature_id_values BY featureid;
    GENERATE group AS patientid, utils.bag_to_svmlight(sorted) AS sparsefeature;
}
grunt> DUMP feature_vectors;
...
(FBF4F34C7437373D,30:3220.000000 7... 9584:30.000000 9743:60.000000 9770:30.000000)
(FBFD014814507B5C,30:270.000000 700:1.000000)
```

## Merge
Next, we can join `targets` and `feature_vectors` to asscociate feature vector with target
```pig
grunt> samples = JOIN targets BY patientid, feature_vectors BY patientid;
grunt> DESCRIBE samples;
samples: {targets::patientid: chararray,targets::eventname: chararray,targets::dateoffset: int,targets::value: int,feature_vectors::patientid: chararray,feature_vectors::sparsefeature: chararray}
grunt> samples = FOREACH samples GENERATE targets::value AS label, feature_vectors::sparsefeature as sparsefeature;
grunt> DESCRIBE samples;
samples: {label: int,sparsefeature: chararray}
grunt> DUMP samples;
...
(0,30:270.000000 117:1.000000 ... 6232:30.000000)
```

## Split and save
We are almost there, just save the `samples`. In machine learning setting, it's a common practice to split data into training and testing samples. We can do that by associate each sample with a random key and split with that random key.

``` pig
grunt> samples = FOREACH samples GENERATE RANDOM() AS assignmentkey, *;
grunt> SPLIT samples INTO testing IF assignmentkey <= 0.20, training OTHERWISE;
grunt> training = FOREACH training GENERATE $1..;
grunt> testing = FOREACH testing GENERATE $1..;
```

Then, we can save 
``` pig
grunt> STORE training INTO 'training' USING PigStorage(' ');
grunt> STORE testing INTO 'testing' USING PigStorage(' ');
```

# Script
Running commands interactively is efficient, but sometimes we want to save the commands for future reuse purpose. We can save the commands we run into a script file (i.e. features.pig) and run the entire script in batch mode.

You can checkout in _sample/pig_ folder. Navigate to there and run the script simply with
```bash
cd bigdata-bootcamp/sample/pig
pig -x local features.pig
```

{% exercise Use data one year before but no earlier than 2 years(i.e. 1 year observation window size).%}
Additional conditions can be applied together with 1 year prediction window. i.e. 
```
filtered_events = FILTER event_target_pairs BY (events::dateoffset <= targets::dateoffset - 365) AND (events::dateoffset >= targets::dateoffset - 730);
```
{% endexercise %}

