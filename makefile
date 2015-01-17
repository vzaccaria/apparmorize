
index.js: index.ls
	echo '#!/usr/bin/env node' > $@
	lsc -p -c $<  >> $@
	chmod +x $@
	make test

clean:
	rm index.js

.phony: test
test:
	rm -rf ./test-dir/*
	cd ./test-dir && ../index.js ./mytest 

