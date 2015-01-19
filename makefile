
all: 
	make index.js

index.js: index.ls
	echo '#!/usr/bin/env node' > $@
	lsc -p -c $<  >> $@
	chmod +x $@

clean:
	rm index.js

.phony: test
test: makefile 
	cd ./test-dir && ./test.sh
