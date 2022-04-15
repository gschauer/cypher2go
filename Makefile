ANTLR_VERSION ?= 4.10

export CGO_ENABLED ?= 0
GOFLAGS += -trimpath
LDFLAGS += -X main.version=$(VERSION)
INSTALL ?= install
INSTALL_PROGRAM ?= $(INSTALL)

prefix = /usr/local
bindir ?= $(prefix)/bin

builddir = bin
distdir = dist
tmpdir = tmp

.PHONY: build generate

generate: parser/cypher_base_listener.go parser/cypher_lexer.go parser/cypher_listener.go parser/cypher_parser.go

all: build

antlr-complete.jar:
	curl --create-dirs -fLsS -o $@ -z $@ 'https://www.antlr.org/download/antlr-$(ANTLR_VERSION)-complete.jar'

build: generate go.mod
	gofmt -s -l -w parser 2>&1 | awk '{print} END{if(NR>0) {exit 1}}'
	go get -v github.com/antlr/antlr4/runtime/Go/antlr@$(ANTLR_VERSION)
	go mod tidy
	@mkdir -p "$(builddir)"
	go build $(GOFLAGS) -ldflags "$(LDFLAGS)" -o "$(builddir)/cypher2go.so" -v ./...

clean:
	rm -rf go.* Cypher*.g4 antlr-complete.jar parser/

Cypher.g4: Cypher_orig.g4
	sed -e 's/\bfunc\b/function/g' \
		-e 's/\bstring\b/str/g' \
		-e 's/\bnewParameter\b/dollarParameter/g' \
		Cypher_orig.g4 >$@.tmp
	@mv $@.tmp $@

Cypher_orig.g4:
	curl -fLsS -o $@ -z $@ 'https://raw.githubusercontent.com/neo4j-contrib/cypher-editor/04e004994d568db0171da7f53e17b037daa93871/cypher-editor-support/src/_generated/Cypher.g4'

go.mod:
	go mod init github.com/gschauer/cypher2go/v4

parser/%.go: Cypher.g4 antlr-complete.jar
	java -Xmx32m -jar antlr-complete.jar -Dlanguage=Go -o parser/ -Werror Cypher.g4
	rm parser/*.interp parser/*.tokens
