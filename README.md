
This repository showcases examples of structured data published to [Tansu](https://tansu.io) schema-backed topics, instantly accessible as [Apache Iceberg tables](https://iceberg.apache.org).

Prerequisites:
- [docker](https://www.docker.com), used to run [tansu](https://tansu.io), [minio](https://min.io), and Apache Iceberg REST Catalog
- [just](https://github.com/casey/just), a handy way to save and run project-specific commands
- [uv](https://github.com/astral-sh/uv), an extremely fast Python package and project manager used to run the [pyiceberg](https://py.iceberg.apache.org) examples

The [justfile](./justfile) contains recipes to run [MinIO](https://min.io), create the buckets, and run the Apache Iceberg REST catalog with [Tansu](https://tansu.io). To start everything:

```shell
just
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
