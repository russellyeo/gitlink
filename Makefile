build:
	swift build -c release

install: build
	install .build/release/gitlink /usr/local/bin/gitlink

uninstall:
	rm -f /usr/local/bin/gitlink

clean:
	swift package clean

.PHONY: build install uninstall clean
