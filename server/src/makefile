SHELL=/bin/bash

clean-dev:
	mongo quick-pomelo-test --eval "db.dropDatabase()"
	echo -e 'select 1\nflushall' | redis-cli


