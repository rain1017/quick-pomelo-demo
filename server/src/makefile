SHELL=/bin/bash

clean-dev:
	mongo ddz-dev --eval "db.dropDatabase()"
	echo -e 'select 1\nflushall' | redis-cli


