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

docker-compose-exec service command *args:
    docker compose exec {{service}} {{command}} {{args}}

minio-mc +args: (docker-compose-exec "minio" "mc" args)

minio-local-alias: (minio-mc "alias" "set" "local" "http://localhost:9000" "minioadmin" "minioadmin")

minio-tansu-bucket: (minio-mc "mb" "local/tansu")

minio-lake-bucket: (minio-mc "mb" "local/lake")

minio-ready-local: (minio-mc "ready" "local")

tansu-up: (docker-compose-up "tansu")

tansu-down: (docker-compose-down "tansu")

iceberg-catalog-up: (docker-compose-up "iceberg-catalog")

iceberg-catalog-down: (docker-compose-down "iceberg-catalog")

topic-create topic: (docker-compose-exec "tansu" "/tansu" "topic" "create" topic)

topic-delete topic: (docker-compose-exec "tansu" "/tansu" "topic" "delete" topic)

cat-produce topic file: (docker-compose-exec "tansu" "/tansu" "cat" "produce" topic file)

cat-consume topic:
    target/debug/tansu cat consume {{topic}} --max-wait-time-ms=5000

# create person topic with schema sample/schema/person.json
person-topic-create: (topic-create "person")

# delete person topic
person-topic-delete: (topic-delete "person")

# produce sample/data/persons.json with schema schema/person.json
person-topic-produce: (cat-produce "person" "data/persons.json")


# create search topic with etc/schema/search.proto
search-topic-create: (topic-create "search")

# delete search topic
search-topic-delete: (topic-delete "search")

# produce data to search topic with etc/schema/search.proto
search-topic-produce:
    echo '{"value": {"query": "abc/def", "page_number": 6, "results_per_page": 13, "corpus": "CORPUS_WEB"}}' | target/debug/tansu cat produce search


# teardown compose, rebuild: minio, db, tansu and lake buckets
server: docker-compose-down minio-up minio-ready-local minio-local-alias minio-tansu-bucket minio-lake-bucket iceberg-catalog-up tansu-up

# produce etc/data/observations.json with schema etc/schema/observation.avsc
observation-produce: (cat-produce "observation" "data/observations.json")

# consume observation topic with schema etc/schema/observation.avsc
observation-consume: (cat-consume "observation")

# create observation topic with schema etc/schema/observation.avsc
observation-topic-create: (topic-create "observation")

# produce etc/data/trips.json with schema etc/schema/taxi.proto
taxi-topic-populate: (cat-produce "taxi" "data/trips.json")

# consume taxi topic with schema etc/schema/taxi.proto
taxi-topic-consume: (cat-consume "taxi")

# create taxi topic with schema etc/schema/taxi.proto
taxi-topic-create: (topic-create "taxi")

# delete taxi topic
taxi-topic-delete: (topic-delete "taxi")

# taxi parquet
# taxi-duckdb-parquet: (duckdb-parquet "taxi")
