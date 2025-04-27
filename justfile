set dotenv-load


docker-compose-up *args:
    docker compose up --detach --wait {{args}}

docker-compose-down *args:
    docker compose down --volumes {{args}}

docker-compose-ps:
    docker compose ps

docker-compose-logs *args:
    docker compose logs {{args}}

minio-up: (docker-compose-up "minio")

minio-down: (docker-compose-down "minio")

minio-mc +args:
    docker compose exec minio /usr/bin/mc {{args}}

minio-local-alias: (minio-mc "alias" "set" "local" "http://localhost:9000" "minioadmin" "minioadmin")

minio-tansu-bucket: (minio-mc "mb" "local/tansu")

minio-lake-bucket: (minio-mc "mb" "local/lake")

minio-ready-local: (minio-mc "ready" "local")

tansu-up: (docker-compose-up "tansu")

tansu-down: (docker-compose-down "tansu")

iceberg-catalog-up: (docker-compose-up "iceberg-catalog")

iceberg-catalog-down: (docker-compose-down "iceberg-catalog")

topic-create topic:
    target/debug/tansu topic create {{topic}}

topic-delete topic:
    target/debug/tansu topic delete {{topic}}

cat-produce topic file:
    target/debug/tansu cat produce {{topic}} {{file}}

cat-consume topic:
    target/debug/tansu cat consume {{topic}} --max-wait-time-ms=5000

# create person topic with schema etc/schema/person.json
person-topic-create: (topic-create "person")

# delete person topic
person-topic-delete: (topic-delete "person")

# produce etc/data/persons.json with schema etc/schema/person.json
person-topic-populate: (cat-produce "person" "etc/data/persons.json")

# produce valid data, that is accepted by the broker
person-topic-produce-valid:
    echo '{"key": "345-67-6543", "value": {"firstName": "John", "lastName": "Doe", "age": 21}}' | target/debug/tansu cat produce person

# produce invalid data, that is rejected by the broker
person-topic-produce-invalid:
    echo '{"key": "ABC-12-4242", "value": {"firstName": "John", "lastName": "Doe", "age": -1}}' | target/debug/tansu cat produce person

# create search topic with etc/schema/search.proto
search-topic-create: (topic-create "search")

# delete search topic
search-topic-delete: (topic-delete "search")

# produce data to search topic with etc/schema/search.proto
search-topic-produce:
    echo '{"value": {"query": "abc/def", "page_number": 6, "results_per_page": 13, "corpus": "CORPUS_WEB"}}' | target/debug/tansu cat produce search

# search parquet
search-duckdb-parquet: (duckdb-parquet "search")

tansu-server:
    target/debug/tansu broker --schema-registry file://./etc/schema 2>&1 | tee tansu.log

# run a broker with configuration from .env
broker:
    target/debug/tansu broker 2>&1 | tee tansu.log

kafka-proxy:
    docker run -d -p 19092:9092 apache/kafka:3.9.0

# run a proxy with configuration from .env
tansu-proxy:
    target/debug/tansu proxy 2>&1 | tee proxy.log

codespace-create:
    gh codespace create \
        --repo $(gh repo view --json nameWithOwner --jq .nameWithOwner) \
        --branch $(git branch --show-current) \
        --machine basicLinux32gb

codespace-delete:
    gh codespace ls \
        --repo $(gh repo view \
            --json nameWithOwner \
            --jq .nameWithOwner) \
        --json name \
        --jq '.[].name' | xargs --no-run-if-empty -n1 gh codespace delete --codespace

codespace-logs:
    gh codespace logs \
        --codespace $(gh codespace ls \
            --repo $(gh repo view \
                --json nameWithOwner \
                --jq .nameWithOwner) \
            --json name \
            --jq '.[].name')

codespace-ls:
    gh codespace list \
        --repo $(gh repo view \
            --json nameWithOwner \
            --jq .nameWithOwner)

codespace-ssh:
    gh codespace ssh \
        --codespace $(gh codespace ls \
            --repo $(gh repo view \
                --json nameWithOwner \
                --jq .nameWithOwner) \
            --json name \
            --jq '.[].name')

all: test miri

benchmark-flamegraph: build docker-compose-down minio-up minio-ready-local minio-local-alias minio-tansu-bucket prometheus-up grafana-up
	flamegraph -- target/debug/tansu broker 2>&1  | tee tansu.log

benchmark: build docker-compose-down minio-up minio-ready-local minio-local-alias minio-tansu-bucket prometheus-up grafana-up
	target/debug/tansu broker 2>&1  | tee tansu.log

otel: build docker-compose-down db-up minio-up minio-ready-local minio-local-alias minio-tansu-bucket prometheus-up grafana-up
	target/debug/tansu broker 2>&1  | tee tansu.log

otel-up: docker-compose-down db-up minio-up minio-ready-local minio-local-alias minio-tansu-bucket prometheus-up grafana-up tansu-up

# teardown compose, rebuild: minio, db, tansu and lake buckets
server: (cargo-build "--package" "tansu-cli") docker-compose-down db-up minio-up minio-ready-local minio-local-alias minio-tansu-bucket minio-lake-bucket iceberg-catalog-up spark-iceberg-up
	target/debug/tansu broker 2>&1  | tee tansu.log

gdb: (cargo-build "--package" "tansu-cli") docker-compose-down db-up minio-up minio-ready-local minio-local-alias minio-tansu-bucket minio-lake-bucket
    rust-gdb --args target/debug/tansu broker

# produce etc/data/observations.json with schema etc/schema/observation.avsc
observation-produce: (cat-produce "observation" "etc/data/observations.json")

# consume observation topic with schema etc/schema/observation.avsc
observation-consume: (cat-consume "observation")

# create observation topic with schema etc/schema/observation.avsc
observation-topic-create: (topic-create "observation")

# observation parquet
observation-duckdb-parquet: (duckdb-k-unnest-v-parquet "observation")

duckdb:
    duckdb -init duckdb-init.sql

# produce etc/data/trips.json with schema etc/schema/taxi.proto
taxi-topic-populate: (cat-produce "taxi" "etc/data/trips.json")

# consume taxi topic with schema etc/schema/taxi.proto
taxi-topic-consume: (cat-consume "taxi")

# create taxi topic with schema etc/schema/taxi.proto
taxi-topic-create: (topic-create "taxi")

# delete taxi topic
taxi-topic-delete: (topic-delete "taxi")

# taxi parquet
taxi-duckdb-parquet: (duckdb-parquet "taxi")
