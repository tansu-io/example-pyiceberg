
This repository showcases examples of structured data published to schema-backed topics, instantly accessible as [Apache Iceberg tables](https://iceberg.apache.org).

Prerequisites:
- **[docker](https://www.docker.com)**, using [compose.yaml](compose.yaml) which runs [tansu](https://tansu.io), [minio](https://min.io) and an [Apache Iceberg REST Catalog](https://iceberg.apache.org/terms/#decoupling-using-the-rest-catalog)
- **[just](https://github.com/casey/just)**, a handy way to save and run project-specific commands
- **[uv](https://github.com/astral-sh/uv)**, an extremely fast Python package and project manager used to run the [pyiceberg](https://py.iceberg.apache.org) examples

[justfile](./justfile) contains recipes to run [MinIO](https://min.io), create the buckets, and run the Apache Iceberg REST catalog with [Tansu](https://tansu.io).

Once you have the prerequisites installed, clone this repository and start everything up with:

```shell
git clone git@github.com:tansu-io/example-pyiceberg.git
cd example-pyiceberg
just up
```

Should result in:

```
✔ Network example-pyiceberg_default
✔ Volume "example-pyiceberg_minio"
✔ Container example-pyiceberg-minio-1
mc: Configuration written to `/tmp/.mc/config.json`. Please update your access credentials.
mc: Successfully created `/tmp/.mc/share`.
mc: Initialized share uploads `/tmp/.mc/share/uploads.json` file.
mc: Initialized share downloads `/tmp/.mc/share/downloads.json` file.
The cluster 'local' is ready
Added `local` successfully.
Bucket created successfully `local/tansu`.
Bucket created successfully `local/lake`.
✔ Container example-pyiceberg-minio-1
✔ Container example-pyiceberg-iceberg-catalog-1
✔ Container example-pyiceberg-tansu-1  Healthy
```

Done! You can now run the examples.

## Employee

Employee is a protocol buffer backed topic, with the following schema [employee.proto](schema/employee.proto):

```proto
syntax = 'proto3';

message Key {
  int32 id = 1;
}

message Value {
  string name = 1;
  string email = 2;
}
```

Sample employee data is in [employees.json](data/employees.json):

```json
[
  {
    "key": { "id": 12321 },
    "value": { "name": "Bob", "email": "bob@example.com" }
  },
  {
    "key": { "id": 32123 },
    "value": { "name": "Alice", "email": "alice@example.com" }
  }
]
```

Create the employee topic:

```bash
just employee-topic-create
```

Publish the sample data onto the employee topic:

```bash
just employee-produce
```

View the data in `pyiceberg`:

```bash
just employee-table-scan
```

Giving the following output:

```text
s3://lake/tansu/employee
table {
  1: id: optional int
  2: name: optional string
  3: email: optional string
}
pyarrow.Table
id: int32
name: large_string
email: large_string
----
id: [[12321,32123]]
name: [["Bob","Alice"]]
email: [["bob@example.com","alice@example.com"]]
```

## Grade

Grade is a JSON schema backed topic, with the following schema [grade.json](schema/grade.json):

```json
{
  "type": "record",
  "name": "Grade",

  "fields": [
    { "name": "key", "type": "string", "pattern": "^\\d{3}-\\d{2}-\\d{4}$" },
    {
      "name": "value",
      "type": {
        "type": "record",
        "fields": [
          { "name": "first", "type": "string" },
          { "name": "last", "type": "string" },
          { "name": "test1", "type": "double" },
          { "name": "test2", "type": "double" },
          { "name": "test3", "type": "double" },
          { "name": "test4", "type": "double" },
          { "name": "final", "type": "double" },
          { "name": "grade", "type": "string" }
        ]
      }
    }
  ]
}
```

Sample grade data is in: [grades.json](data/grades.json):

```json
[
  {
    "key": "123-45-6789",
    "value": {
      "lastName": "Alfalfa",
      "firstName": "Aloysius",
      "test1": 40.0,
      "test2": 90.0,
      "test3": 100.0,
      "test4": 83.0,
      "final": 49.0,
      "grade": "D-"
    }
  },
  ...
]
```

Create the grade topic:

```bash
just grade-topic-create
```

Publish the sample data onto the grade topic:

```bash
just grade-produce
```

View the data in `pyiceberg`:

```bash
just grade-table-scan
```

Giving the following output:

```text
s3://lake/tansu/grade
table {
  1: key: optional string
  2: value: optional struct<3: final: optional double, 4: first: optional string, 5: grade: optional string, 6: last: optional string, 7: test1: optional double, 8: test2: optional double, 9: test3: optional double, 10: test4: optional double>
}
pyarrow.Table
key: large_string
value: struct<final: double, first: large_string, grade: large_string, last: large_string, test1: double, test2: double, test3: double, test4: double>
  child 0, final: double
  child 1, first: large_string
  child 2, grade: large_string
  child 3, last: large_string
  child 4, test1: double
  child 5, test2: double
  child 6, test3: double
  child 7, test4: double
----
key: [["123-45-6789","123-12-1234","567-89-0123","087-65-4321","456-78-9012",...,"087-75-4321","456-71-9012","234-56-2890","345-67-3901","632-79-9439"]]
value: [
  -- is_valid: all not null
  -- child 0 type: double
[49,48,44,47,45,...,45,77,90,4,40]
  -- child 1 type: large_string
["Aloysius","University","Gramma","Electric","Fred",...,"Jim","Ima","Benny","Boy","Harvey"]
  -- child 2 type: large_string
["D-","D+","C","B-","A-",...,"C+","B-","B-","B","C"]
  -- child 3 type: large_string
["Alfalfa","Alfred","Gerty","Android","Bumpkin",...,"Dandy","Elephant","Franklin","George","Heffalump"]
  -- child 4 type: double
[40,41,41,42,43,...,47,45,50,40,30]
  -- child 5 type: double
[90,97,80,23,78,...,1,1,1,1,1]
  -- child 6 type: double
[100,96,60,36,88,...,23,78,90,11,20]
  -- child 7 type: double
[83,97,40,45,77,...,36,88,80,-1,30]]
```

## Observation

Observation is an Avro backed topic, with the following schema [observation.avsc](schema/observation.avsc):

```json
{
  "type": "record",
  "name": "observation",
  "fields": [
    { "name": "key", "type": "string", "logicalType": "uuid" },
    {
      "name": "value",
      "type": "record",
      "fields": [
        { "name": "amount", "type": "double" },
        { "name": "unit", "type": "enum", "symbols": ["CELSIUS", "MILLIBAR"] }
      ]
    }
  ]
}
```

Sample observation data, is in: [observations.json](data/observations.json):

```json
[
  {
    "key": "1E44D9C2-5E7A-443B-BF10-2B1E5FD72F15",
    "value": { "amount": 23.2, "unit": "CELSIUS" }
  },
  ...
]
```

Create the observation topic:

```bash
just observation-topic-create
```

Publish the sample data onto the observation topic:

```bash
just observation-produce
```

View the data in `pyiceberg`:

```bash
just observation-table-scan
```

Giving the following output:

```text
s3://lake/tansu/observation
table {
  1: key: optional string
  2: value: optional struct<3: amount: optional double, 4: unit: optional string>
}
pyarrow.Table
key: large_string
value: struct<amount: double, unit: large_string>
  child 0, amount: double
  child 1, unit: large_string
----
key: [["1e44d9c2-5e7a-443b-bf10-2b1e5fd72f15","1e44d9c2-5e7a-443b-bf10-2b1e5fd72f15","1e44d9c2-5e7a-443b-bf10-2b1e5fd72f15","1e44d9c2-5e7a-443b-bf10-2b1e5fd72f15","1e44d9c2-5e7a-443b-bf10-2b1e5fd72f15","1e44d9c2-5e7a-443b-bf10-2b1e5fd72f15","1e44d9c2-5e7a-443b-bf10-2b1e5fd72f15","1e44d9c2-5e7a-443b-bf10-2b1e5fd72f15","1e44d9c2-5e7a-443b-bf10-2b1e5fd72f15","1e44d9c2-5e7a-443b-bf10-2b1e5fd72f15"]]
value: [
  -- is_valid: all not null
  -- child 0 type: double
[23.2,1027,22.8,1023,22.5,1018,23.1,1020,23.4,1025]
  -- child 1 type: large_string
["CELSIUS","MILLIBAR","CELSIUS","MILLIBAR","CELSIUS","MILLIBAR","CELSIUS","MILLIBAR","CELSIUS","MILLIBAR"]]
```

## Person

Person is a JSON schema backed topic, with the following schema [person.json](schema/person.json):

```json
{
  "title": "Person",
  "type": "object",
  "properties": {
    "key": {
      "type": "string",
      "pattern": "^\\d{3}-\\d{2}-\\d{4}$"
    },
    "value": {
      "type": "object",
      "properties": {
        "firstName": {
          "type": "string",
          "description": "The person's first name."
        },
        "lastName": {
          "type": "string",
          "description": "The person's last name."
        },
        "age": {
          "description": "Age in years which must be equal to or greater than zero.",
          "type": "integer",
          "minimum": 0
        }
      }
    }
  }
}
```

Sample person data, is in [persons.json](data/persons.json):

```json
[
  {
    "key": "123-45-6789",
    "value": { "lastName": "Alfalfa", "firstName": "Aloysius", "age": 21 }
  },
  ...
]
```

Create the person topic:

```bash
just person-topic-create
```

Publish the sample data onto the person topic:

```bash
just person-produce
```

View the data in `pyiceberg`:

```bash
just person-table-scan
```

Giving the following output:

```text
s3://lake/tansu/person
table {
  1: key: optional string
  2: value: optional struct<3: age: optional long, 4: firstName: optional string, 5: lastName: optional string>
}
pyarrow.Table
key: large_string
value: struct<age: int64, firstName: large_string, lastName: large_string>
  child 0, age: int64
  child 1, firstName: large_string
  child 2, lastName: large_string
----
key: [["123-45-6789","123-12-1234","567-89-0123","087-65-4321","456-78-9012",...,"087-75-4321","456-71-9012","234-56-2890","345-67-3901","632-79-9439"]]
value: [
  -- is_valid: all not null
  -- child 0 type: int64
[21,52,35,23,72,...,56,45,54,91,17]
  -- child 1 type: large_string
["Aloysius","University","Gamma","Electric","Fred",...,"Jim","Ima","Benny","Boy","Harvey"]
  -- child 2 type: large_string
["Alfalfa","Alfred","Gerty","Android","Bumpkin",...,"Dandy","Elephant","Franklin","George","Heffalump"]]
```

## Search

Search is a protocol buffer backedd topic, with the following schema [search.proto](schema/search.proto):

```proto
syntax = 'proto3';

enum Corpus {
  CORPUS_UNSPECIFIED = 0;
  CORPUS_UNIVERSAL = 1;
  CORPUS_WEB = 2;
  CORPUS_IMAGES = 3;
  CORPUS_LOCAL = 4;
  CORPUS_NEWS = 5;
  CORPUS_PRODUCTS = 6;
  CORPUS_VIDEO = 7;
}

message Value {
  string query = 1;
  int32 page_number = 2;
  int32 results_per_page = 3;
  Corpus corpus = 4;
}
```

Sample search data, is in [searches.json](data/searches.json):

```json
[
  {
    "value": {
      "query": "abc/def",
      "page_number": 6,
      "results_per_page": 13,
      "corpus": "CORPUS_WEB"
    }
  }
]
```

Create the search topic:

```bash
just search-topic-create
```

Publish the sample data onto the search topic:

```bash
just search-produce
```

View the data in `pyiceberg`:

```bash
just search-table-scan
```

Giving the following output:

```text
s3://lake/tansu/search
table {
  1: query: optional string
  2: page_number: optional int
  3: results_per_page: optional int
  4: corpus: optional int
}
pyarrow.Table
query: large_string
page_number: int32
results_per_page: int32
corpus: int32
----
query: [["abc/def"]]
page_number: [[6]]
results_per_page: [[13]]
corpus: [[2]]
```

## Taxi

Taxi is a protocol buffer backed topic, with the following schema [taxi.proto](schema/taxi.proto):

```proto
syntax = 'proto3';

enum Flag {
    N = 0;
    Y = 1;
}

message Value {
  int64 vendor_id = 1;
  int64 trip_id = 2;
  float trip_distance = 3;
  double fare_amount = 4;
  Flag store_and_fwd = 5;
}
```

Sample trip data, is in [trips.json](data/trips.json):

```json
[
  {
    "value": {
      "vendor_id": 1,
      "trip_id": 1000371,
      "trip_distance": 1.8,
      "fare_amount": 15.32,
      "store_and_fwd": "N"
    }
  },
  ...
]
```

Create the taxi topic:

```bash
just taxi-topic-create
```

Publish the sample data onto the taxi topic:

```bash
just taxi-produce
```

View the data in `pyiceberg`:

```bash
just taxi-table-scan
```

Giving the following output:

```text
s3://lake/tansu/taxi
table {
  1: vendor_id: optional long
  2: trip_id: optional long
  3: trip_distance: optional float
  4: fare_amount: optional double
  5: store_and_fwd: optional int
}
pyarrow.Table
vendor_id: int64
trip_id: int64
trip_distance: float
fare_amount: double
store_and_fwd: int32
----
vendor_id: [[1,2,2,1]]
trip_id: [[1000371,1000372,1000373,1000374]]
trip_distance: [[1.8,2.5,0.9,8.4]]
fare_amount: [[15.32,22.15,9.01,42.13]]
store_and_fwd: [[0,0,0,1]]
```
