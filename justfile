set dotenv-load

# teardown existing, start: minio, when ready create: tansu and lake buckets, and then: iceberg catalog and tansu
up: docker-compose-down minio-up minio-ready-local minio-local-alias minio-tansu-bucket minio-lake-bucket iceberg-catalog-up tansu-up

[private]
docker-compose-up *args:
    docker compose up --detach --wait {{args}}

[private]
docker-compose-down *args:
    docker compose down --volumes {{args}}

[private]
docker-compose-ps:
    docker compose ps

[private]
docker-compose-logs *args:
    docker compose logs {{args}}

[private]
minio-up: (docker-compose-up "minio")

[private]
minio-down: (docker-compose-down "minio")

[private]
docker-compose-exec service command *args:
    docker compose exec {{service}} {{command}} {{args}}

[private]
minio-mc +args: (docker-compose-exec "minio" "mc" args)

[private]
minio-local-alias: (minio-mc "alias" "set" "local" "http://localhost:9000" "minioadmin" "minioadmin")

[private]
minio-tansu-bucket: (minio-mc "mb" "local/tansu")

[private]
minio-lake-bucket: (minio-mc "mb" "local/lake")

[private]
minio-ready-local: (minio-mc "ready" "local")

[private]
tansu-up: (docker-compose-up "tansu")

[private]
tansu-down: (docker-compose-down "tansu")

[private]
iceberg-catalog-up: (docker-compose-up "iceberg-catalog")

[private]
iceberg-catalog-down: (docker-compose-down "iceberg-catalog")

[private]
topic-create topic: (docker-compose-exec "tansu" "/tansu" "topic" "create" topic)

[private]
topic-delete topic: (docker-compose-exec "tansu" "/tansu" "topic" "delete" topic)

[private]
cat-produce topic file: (docker-compose-exec "tansu" "/tansu" "cat" "produce" topic file)

[private]
cat-consume topic: (docker-compose-exec "tansu" "/tansu" "cat" "consume" topic "--max-wait-time-ms=5000")

[private]
iceberg-table-scan table:
    uv run iceberg_table_scan.py {{table}}


## Employee

# create employee topic with schema/employee.proto
employee-topic-create: (topic-create "employee")

# produce data/persons.json with schema/person.json
employee-produce: (cat-produce "employee" "data/employees.json")

# consume employee topic
employee-consume: (cat-consume "employee")

# iceberg employee table scan
employee-table-scan: (iceberg-table-scan "tansu.employee")


## Person

# create person topic with schema/person.json
person-topic-create: (topic-create "person")

# produce data/persons.json with schema/person.json
person-produce: (cat-produce "person" "data/persons.json")

# consume person topic
person-consume: (cat-consume "person")

# iceberg person table scan
person-table-scan: (iceberg-table-scan "tansu.person")


## Search

# create search topic with schema/search.proto
search-topic-create: (topic-create "search")

# produce data/searches.json with schema/search.proto
search-produce: (cat-produce "search" "data/searches.json")

# consume search topic
search-consume: (cat-consume "search")

# iceberg search table scan
search-table-scan: (iceberg-table-scan "tansu.search")


## Observation

# create observation topic with schema etc/schema/observation.avsc
observation-topic-create: (topic-create "observation")

# produce data/observations.json with schema/observation.avsc
observation-produce: (cat-produce "observation" "data/observations.json")

# consume observation topic
observation-consume: (cat-consume "observation")

# iceberg observation table scan
observation-table-scan: (iceberg-table-scan "tansu.observation")


## Taxi

# create taxi topic with schema etc/schema/taxi.proto
taxi-topic-create: (topic-create "taxi")

# produce data/trips.json with schema schema/taxi.proto
taxi-produce: (cat-produce "taxi" "data/trips.json")

# consume taxi topic
taxi-consume: (cat-consume "taxi")

# iceberg taxi table scan
taxi-table-scan: (iceberg-table-scan "tansu.taxi")


## Grade

# create grade topic with schema etc/schema/grades.proto
grade-topic-create: (topic-create "grade")

# produce data/grades.json with schema schema/grades.proto
grade-produce: (cat-produce "grade" "data/grades.json")

# consume grade topic
grade-consume: (cat-consume "grade")

# iceberg grade table scan
grade-table-scan: (iceberg-table-scan "tansu.grade")
