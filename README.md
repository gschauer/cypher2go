# cypher2go - Go library for parsing Neo4j's Cypher query language

cypher2go is a ready-to-use library for Go applications,
which make use of the Cypher query language parser.
It provides the same parsing capabilities as
[Neo4j Browser](https://github.com/neo4j/neo4j-browser) -
the general purpose web interface for Neo4j.
More specifically, it includes the Cypher grammar for Neo4j 4.3, as provided by
[Cypher Editor](https://github.com/neo4j-contrib/cypher-editor).
The parser is solely generated from the ANTLR grammar.

The main purpose of cypher2go is to enable other projects to use the parser

- without installing Java and compiling it on the fly, or
- storing approx. 1.5 MB of generated source code in the project repository.

Note that this library requires ANTLR runtime 4.10 or newer,
which is incompatible with older ANTLR versions.
See also https://github.com/antlr/antlr4/releases/tag/4.10 for further details.

You can use the `Makefile` to generate the cypher2go with another ANTLR version.
The dependencies in the Go module will be adjusted automatically.

```shell
ANTLR_VERSION=4.7.2 make clean build
```

## Usage

```go
import (
	"github.com/gschauer/cypher2go/parser"
	"github.com/antlr/antlr4/runtime/Go/antlr"
)

func Parse(input string) (antlr.ParseTree, *CustomListener, *ErrorListener) {
	// Custom listeners should implement some method declared by CypherListener.
	// It is supposed to keep track of variables, patterns, etc.
	// (see cypher_listener.go)
	l := NewCustomListener()
	errL := &ErrorListener{}

	chars := antlr.NewInputStream(input)
	lexer := parser.NewCypherLexer(chars)
	lexer.RemoveErrorListeners()
	lexer.AddErrorListener(errL)
	tokens := antlr.NewCommonTokenStream(lexer, antlr.TokenDefaultChannel)

	p := parser.NewCypherParser(tokens)
	p.BuildParseTrees = true
	p.RemoveErrorListeners()
	p.AddErrorListener(errL)
	p.AddParseListener(l)
	parseTree := p.Cypher()
	return parseTree, l, errL
}
```

## Similar Projects

There are a couple of projects, which provide generated Go code for different Cypher versions.
The main difference is that they are using a newer grammar,
published by [openCypher](https://opencypher.org/resources/).

- https://github.com/a-poor/cypher
- https://github.com/jtejido/go-opencypher

It is noteworthy that there are also several other parsers and transpilers
for other programming languages, including, but not limited to

- https://github.com/cleishm/libcypher-parser - C parser library / linter for older Cypher versions
- https://github.com/microsoft/openCypherTranspiler - C# transpiler for openCypher to T-SQL
