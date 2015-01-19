
all: 
	make index.js
	make test

index.js: index.ls
	echo '#!/usr/bin/env node' > $@
	lsc -p -c $<  >> $@
	chmod +x $@

clean:
	rm index.js

.phony: test
test: makefile 
	./index.js install -n 4
