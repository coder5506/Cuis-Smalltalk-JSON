'From Cuis7.3 [latest update: #7248] on 30 July 2025 at 6:03:16 am'!
'Description '!
!provides: 'JSON' 1 31!
!requires: 'Unicode' 1 6 nil!
SystemOrganization addCategory: #JSON!


!classDefinition: #Json category: #JSON!
Object subclass: #Json
	instanceVariableNames: 'stream ctorMap'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'JSON'!
!classDefinition: 'Json class' category: #JSON!
Json class
	instanceVariableNames: ''!

!classDefinition: #JsonBuilder category: #JSON!
Object subclass: #JsonBuilder
	instanceVariableNames: 'stream context separator'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'JSON'!
!classDefinition: 'JsonBuilder class' category: #JSON!
JsonBuilder class
	instanceVariableNames: 'characterEscapes'!

!classDefinition: #JsonObject category: #JSON!
OrderedDictionary subclass: #JsonObject
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'JSON'!
!classDefinition: 'JsonObject class' category: #JSON!
JsonObject class
	instanceVariableNames: ''!

!classDefinition: #JsonDomainError category: #JSON!
Error subclass: #JsonDomainError
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'JSON'!
!classDefinition: 'JsonDomainError class' category: #JSON!
JsonDomainError class
	instanceVariableNames: ''!

!classDefinition: #JsonSyntaxError category: #JSON!
Error subclass: #JsonSyntaxError
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'JSON'!
!classDefinition: 'JsonSyntaxError class' category: #JSON!
JsonSyntaxError class
	instanceVariableNames: ''!


!Json commentStamp: '<historical>' prior: 0!
This class reads and writes JSON format data - strings, numbers, boolean, nil, arrays and dictionaries. See http://www.json.org . It has been extended with syntax for invoking a prearranged list of constructors on read objects.!

!JsonDomainError commentStamp: '<historical>' prior: 0!
Object cannot be converted to a JSON serializable form.  See comment at Object>>#asJsonObject.!

!JsonSyntaxError commentStamp: '<historical>' prior: 0!
Class Json signals instances of me when an input stream contains invalid JSON input.!

!Json methodsFor: 'accessing' stamp: 'ess 6/24/2025 10:49:05'!
ctorMap

	^ ctorMap! !

!Json methodsFor: 'accessing' stamp: 'ess 6/24/2025 10:49:13'!
ctorMap: m

	ctorMap := m! !

!Json methodsFor: 'accessing' stamp: 'tonyg 8/16/2005 20:20'!
stream
	"Answer the value of stream"

	^ stream! !

!Json methodsFor: 'accessing' stamp: 'ess 6/24/2025 10:50:41'!
stream: aStream
	"Set the value of stream"
	"aStream must be on a String.
	This means that it should contain only Characters (i.e. ISO 8859-15)"

	stream := aStream
	
	"Do not reset the stream"
	"
	stream reset
	"! !

!Json methodsFor: 'parsing' stamp: 'ess 6/24/2025 10:54:02'!
readAny
	"This is the main entry point for the JSON parser. See also readFrom: on the class side."

	| c |
	self skipWhitespace.
	c := stream peek.
	c = ${ ifTrue: [
		stream next.
		^ self readDictionary ].
	c = $[ ifTrue: [
		stream next.
		^ self readArray ].
	c = $" ifTrue: [
		stream next.
		^ self readString ].
	c = $t ifTrue: [
		^ self
			consume: 'true'
			returning: true ].
	c = $f ifTrue: [
		^ self
			consume: 'false'
			returning: false ].
	c = $n ifTrue: [
		^ self
			consume: 'null'
			returning: nil ].
	c = $@ ifTrue: [
		stream next.
		^ self readConstructor ].
	c = $- ifTrue: [  "Negative number or '-Infinity' - > Float negativeInfinity "
		stream next.
		^ self readAny negated ].
	(Json numbersMayContain: c) ifTrue: [
		^ self readNumber ].
	c = $N ifTrue: [
		^ self
			consume: 'NaN'
			returning: Float nan ].
	c = $I ifTrue: [
		^ self
			consume: 'Infinity'
			returning: Float infinity ].
	^ JsonSyntaxError signal: 'Unknown Json input'! !

!Json methodsFor: 'parsing' stamp: 'ess 6/24/2025 10:51:16'!
readFrom: aStream
	"aStream must be on a String.
	This means that it should contain only Characters (i.e. ISO 8859-15).
	To handle a ByteArray with utf-8, please do 'String fromUtf8: aByteArray' or similar"

	aStream atEnd ifTrue: [
		^ JsonObject new ].
	self stream: aStream.
	^ self readAny! !

!Json methodsFor: 'private' stamp: 'ess 6/24/2025 10:38:43'!
consume: aString returning: anObject

	aString do: [ :c |
		stream next = c ifFalse: [
			^ JsonSyntaxError signal: 'Expected ''', aString, '''' ] ].
	^ anObject! !

!Json methodsFor: 'private' stamp: 'ess 6/24/2025 10:39:01'!
interpretStringEscapeTo: aStream

	| c |
	c := stream next.
	c = $b ifTrue: [
		aStream nextPut: Character backspace.
		^ self ].
	c = $n ifTrue: [
		aStream nextPut: Character lf.
		^ self ].
	c = $f ifTrue: [
		aStream nextPut: Character newPage.
		^ self ].
	c = $r ifTrue: [
		aStream nextPut: Character cr.
		^ self ].
	c = $t ifTrue: [
		aStream nextPut: Character tab.
		^ self ].
	c = $u ifTrue: [
		self unescapeUnicodeTo: aStream.
		^ self ].
	aStream nextPut: c! !

!Json methodsFor: 'private' stamp: 'ess 6/24/2025 10:42:32'!
readArray

	| a |
	a := OrderedCollection new.
	self skipWhitespace.
	(stream peekFor: $]) ifTrue: [
		^ #() ].
	[
		a add: self readAny.
		self skipWhitespace.
		(stream peekFor: $]) ifTrue: [
			^ a asArray].
		(stream peekFor: $, ) ifFalse: [
			^ JsonSyntaxError signal: 'Missing comma' ]
	] repeat! !

!Json methodsFor: 'private' stamp: 'ess 6/24/2025 10:41:03'!
readConstructor

	| s c v ctor |
	s := WriteStream on: ''.
	[
		c := stream peek.
		c ifNil: [
			^ JsonSyntaxError signal: 'Premature EOF reading constructor name' ].
		((c = $.) or: [ c isLetter ])
			ifTrue: [
				s nextPut: c.
				stream next ]
			ifFalse: [
				v := self readAny.
				s := s contents.
				ctor := ctorMap ifNotNil: [
					ctor := ctorMap
						at: s
						ifAbsent: [ nil ] ].
				ctor ifNil: [
					^ JsonSyntaxError signal: 'Unknown ctor ', s ].
				^ ctor constructFromJson: v ]
	] repeat! !

!Json methodsFor: 'private' stamp: 'ess 6/24/2025 10:42:51'!
readDictionary

	| m k v needComma |
	m := JsonObject new.
	needComma := false.
	[
		self skipWhitespace.
		(stream peekFor: $}) ifTrue: [
			^ m ].
		needComma
			ifFalse: [
				needComma := true ]
			ifTrue: [
				(stream peekFor: $,) ifFalse: [
					^ JsonSyntaxError signal: 'Missing comma' ].
				self skipWhitespace ].
		(stream peekFor: $") ifFalse: [
			^ JsonSyntaxError signal: 'Key in dictionary must be string' ].
		k := self readString.
		self skipWhitespace.
		(stream peekFor: $:) ifFalse: [
			^ JsonSyntaxError signal: 'Missing colon' ].
		v := self readAny.
		m
			at: k
			put: v
	] repeat! !

!Json methodsFor: 'private' stamp: 'ess 6/24/2025 10:43:47'!
readNumber

	| acc c |
	acc := WriteStream on: ''.
	[
		c := stream peek.
		(c isNil not and: [ Json numbersMayContain: c ]) ifFalse: [
			[ ^ acc contents asNumber ]
				on: Error
				do: [
					^ JsonSyntaxError signal: 'Invalid number' ] ].
		acc nextPut: c.
		stream next
	] repeat

	"Allow Nan, Infinity and -Infinity.
	Breaks on non-PositionableStreams, like StdIOReadStream stdin"
	"
	^Number readFrom: stream
	"! !

!Json methodsFor: 'private' stamp: 'ess 6/24/2025 10:44:17'!
readString

	| s c |
	s := WriteStream on: ''.
	[
		c := stream next.
		c = $\
			ifTrue: [
				self interpretStringEscapeTo: s ]
			ifFalse: [
				c = $" ifTrue: [
					^ s contents ].
				s nextPut: c ]
	] repeat! !

!Json methodsFor: 'private' stamp: 'ess 6/24/2025 10:45:02'!
skipComment

	stream peek = $/ ifTrue: [
		stream next.
		stream peek = $/
			ifTrue: [
				self skipToEndOfLine ]
			ifFalse: [
				stream peek = $*
					ifTrue: [
						stream next.
						self skipCommentBody ]
					ifFalse: [
						^ JsonSyntaxError signal: 'Invalid comment syntax' ] ] ]! !

!Json methodsFor: 'private' stamp: 'ess 6/24/2025 10:45:28'!
skipCommentBody

	[
		[ stream next = $* ] whileFalse.
		stream peek = $/
	] whileFalse.
	stream next. "skip that last slash"
	self skipWhitespace! !

!Json methodsFor: 'private' stamp: 'ess 6/24/2025 10:45:58'!
skipToEndOfLine

	| cr lf |
	cr := Character cr.
	lf := Character lf.
	[ | c | (c := stream peek) = cr or: [ c = lf ] ]
		whileFalse: [ stream next ].
	self skipWhitespace! !

!Json methodsFor: 'private' stamp: 'ess 6/24/2025 10:46:34'!
skipWhitespace

	[ stream peek isSeparator ]
		whileTrue: [ stream next ].
	self skipComment! !

!Json methodsFor: 'private' stamp: 'ess 6/24/2025 10:48:56'!
unescapeUnicodeTo: aStream
	"Next 4 chars from `stream` are hex unicode point value"

	| string codepoint leading trailing |
	string := String newFrom: { stream next. stream next. stream next. stream next }.
	codepoint := Codepoint fromHex: string.

	"First unicode escape may be part of a surrogate pair."
	(Codepoint isLeadingSurrogate: codepoint) ifTrue: [
		stream next = $\
			ifFalse: [
				stream skip: -1 ]
			ifTrue: [
				stream next = $u
					ifFalse: [
						stream skip: -2 ]
					ifTrue: [
						leading := codepoint.
						string := String newFrom: { stream next. stream next. stream next. stream next }.
						trailing := Codepoint fromHex: string.
						codepoint := Codepoint
							fromSurrogate: leading
							pair: trailing
							ifAbsent: [
								stream skip: -6.
								Codepoint replacementCharacter ] ] ] ].

	"JSON permits invalid codepoints, but we can't do anything with them."
	codepoint := Codepoint
		asValid: codepoint
		ifAbsent: [ Codepoint replacementCharacter ].		
	aStream nextPut: (Character codePoint: codepoint)! !

!Json class methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 10:33:06'!
mimeType

	^ 'application/json'! !

!Json class methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 10:33:42'!
newWithConstructors: aCollection

	| m |
	m := Dictionary new.
	aCollection do: [ :each |
		(each isKindOf: Association)
			ifTrue: [
				m add: each ]
			ifFalse: [
				m
					at: each name asString
					put: each ] ].
	^ self new
		ctorMap: m;
		yourself! !

!Json class methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 10:34:08'!
numbersMayContain: aChar

	^ aChar isDigit
		or: [ #($- $+ $. $e $E) includes: aChar ]! !

!Json class methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 10:34:16'!
readFrom: aStream

	^ self new
		readFrom: aStream! !

!Json class methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 10:34:31'!
render: anObject

	| s |
	s := WriteStream on: String new.
	anObject jsonWriteOn: s.
	^ s contents! !

!Json class methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 10:34:40'!
render: anObject withConstructor: aConstructorName on: aStream

	aStream nextPutAll: '@', aConstructorName.
	anObject jsonWriteOn: aStream! !

!Json class methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 10:35:13'!
renderInstanceVariables: aCollection of: anObject on: aStream

	| map |
	map := Dictionary new.
	aCollection do: [ :ivarName |
		map
			at: ivarName
			put: (anObject instVarNamed: ivarName) ].
	self
		render: map
		withConstructor: anObject class name asString
		on: aStream! !

!Json class methodsFor: 'as yet unclassified' stamp: 'ess 6/23/2025 16:51:45'!
stringify: anObject

	^ JsonBuilder
		stringify: anObject! !

!Json class methodsFor: 'as yet unclassified' stamp: 'ess 6/23/2025 16:52:41'!
write: anObject on: aStream

	JsonBuilder
		write: anObject
		on: aStream! !

!JsonBuilder methodsFor: 'encoding' stamp: 'ess 6/24/2025 10:31:09'!
writeArray: aCollection
	"Write an array using the default representation of all objects in aCollection."

	self
		writeArray: aCollection
		do: [ :each |
			self writeArrayElement: each ]! !

!JsonBuilder methodsFor: 'encoding' stamp: 'ess 6/24/2025 10:24:51'!
writeArray: aCollection do: aUnaryBlock
	"aUnaryBlock should send #writeArrayElementDo: to add an element to the array."

	self writeArrayDo: [
		aCollection do: aUnaryBlock ]! !

!JsonBuilder methodsFor: 'encoding' stamp: 'ess 6/24/2025 10:23:31'!
writeArrayDo: aNullaryBlock
	"aNullaryBlock should send #writeArrayElementDo: for each element it adds to the array."

	self
		writeCollectionBegin: $[
		end: $]
		do: aNullaryBlock! !

!JsonBuilder methodsFor: 'encoding' stamp: 'ess 6/24/2025 10:29:28'!
writeArrayElement: anObject
	"Write the default representation of anObject as the next array element."

	self writeArrayElementDo: [
		self writeValue: anObject ]! !

!JsonBuilder methodsFor: 'encoding' stamp: 'ess 6/24/2025 10:27:03'!
writeArrayElementDo: aNullaryBlock
	"aNullaryBlock should write the value of the next array element."

	self requireArrayContext.
	self ensuringSeparatorsDo: [
		self inValueContextDo: aNullaryBlock ]! !

!JsonBuilder methodsFor: 'encoding' stamp: 'ess 6/24/2025 08:23:48'!
writeFalse

	self requireValueContext.
	stream
		nextPutAll: 'false'! !

!JsonBuilder methodsFor: 'encoding' stamp: 'ess 6/24/2025 08:23:48'!
writeNull

	self requireValueContext.
	stream
		nextPutAll: 'null'! !

!JsonBuilder methodsFor: 'encoding' stamp: 'ess 6/24/2025 08:23:48'!
writeNumber: aNumber

	self requireValueContext.
	aNumber
		printOn: stream
		base: 10! !

!JsonBuilder methodsFor: 'encoding' stamp: 'ess 6/24/2025 10:32:11'!
writeObject: aCollection
	"Write an object using the default representation of all keys and values in aCollection."

	self
		writeObject: aCollection
		do: [ :each |
			self
				writeObjectKey: each key
				value: each value ]! !

!JsonBuilder methodsFor: 'encoding' stamp: 'ess 6/24/2025 11:02:21'!
writeObject: aCollection do: aUnaryBlock
	"aUnaryBlock should send #writeObjectKey:do: to add a member to the object."


	self writeObjectDo: [
		aCollection associationsDo: aUnaryBlock ]! !

!JsonBuilder methodsFor: 'encoding' stamp: 'ess 6/24/2025 11:03:49'!
writeObjectDo: aNullaryBlock
	"aNullaryBlock should send #writeObjectKey:do: for each member it adds to the object."

	self
		writeCollectionBegin: ${
		end: $}
		do: aNullaryBlock! !

!JsonBuilder methodsFor: 'encoding' stamp: 'ess 6/24/2025 10:28:42'!
writeObjectKey: key do: aNullaryBlock
	"aNullaryBlock should write the value of the next object member."
	"key should be a string or an object that can convert to a string, and will be written as the key of the object member createdy by aNullaryBlock."

	self requireObjectContext.
	self ensuringSeparatorsDo: [
		self writeString: key asString.
		stream nextPut: $:.
		self inValueContextDo: aNullaryBlock ]! !

!JsonBuilder methodsFor: 'encoding' stamp: 'ess 6/24/2025 10:29:58'!
writeObjectKey: key value: value
	"Write the default representation of value as the next object member."

	self
		writeObjectKey: key
		do: [ self writeValue: value ]! !

!JsonBuilder methodsFor: 'encoding' stamp: 'ess 6/24/2025 08:23:41'!
writeString: aString

	self requireStringContext.
	self
		inChildContext: $"
		do: [
			stream nextPut: $".
			[	aString do: [ :each |
					(self species characterEscape: each)
						ifNotNil: [ :it |
							stream nextPutAll: it ]
						ifNil: [
							stream nextPut: each ] ]
			] ensure: [
				stream nextPut: $" ] ]! !

!JsonBuilder methodsFor: 'encoding' stamp: 'ess 6/24/2025 08:23:48'!
writeTrue

	self requireValueContext.
	stream
		nextPutAll: 'true'! !

!JsonBuilder methodsFor: 'encoding' stamp: 'ess 6/24/2025 08:23:48'!
writeValue: anObject

	self requireValueContext.
	anObject
		buildJson: self! !

!JsonBuilder methodsFor: 'private' stamp: 'ess 6/23/2025 10:49:01'!
setStream: aStream

	stream := aStream.
	^ self! !

!JsonBuilder methodsFor: 'private-asserting' stamp: 'ess 6/24/2025 08:27:20'!
requireArrayContext
	"Check that we're in an array when writing array elements."

	self
		assert: self isArrayContext
		description: 'Must be called only in an array context'! !

!JsonBuilder methodsFor: 'private-asserting' stamp: 'ess 6/24/2025 08:36:12'!
requireCollectionContext
	"Check that we're in an array or object when writing element separators."

	| isCollectionContext |
	isCollectionContext := self isArrayContext or: [ self isObjectContext ].
	self
		assert: isCollectionContext
		description: 'Must be called only in an array or object context'! !

!JsonBuilder methodsFor: 'private-asserting' stamp: 'ess 6/24/2025 08:27:32'!
requireObjectContext
	"Check that we're in an object when writing object members."

	self
		assert: self isObjectContext
		description: 'Must be called only in an object context'! !

!JsonBuilder methodsFor: 'private-asserting' stamp: 'ess 6/24/2025 08:36:43'!
requireStringContext
	"Check that we're expecting a value or an object key when writing a string."

	| isStringContext |
	isStringContext := self isValueContext or: [ self isObjectContext ].
	self
		assert: isStringContext
		description: 'Must be called only in a value or object context'! !

!JsonBuilder methodsFor: 'private-asserting' stamp: 'ess 6/24/2025 08:30:12'!
requireValueContext
	"Check that we're not expecting a separator or object key when writing a value."

	self
		assert: self isValueContext
		description: 'Must be called only in a value context'! !

!JsonBuilder methodsFor: 'private-encoding' stamp: 'ess 6/24/2025 08:32:13'!
ensuringSeparatorsDo: aNullaryBlock
	"Output separators between array elements or object members."

	| lastContext |
	self requireCollectionContext.
	lastContext := context.
	separator ifNotNil: [
		stream nextPut: separator ].
	[ aNullaryBlock value ]
		ensure: [
			context := lastContext.
			separator := $, ]! !

!JsonBuilder methodsFor: 'private-encoding' stamp: 'ess 6/24/2025 08:38:34'!
inChildContext: contextCharacter do: aNullaryBlock
	"Save and restore the current context while evaluating aNullaryBlock in a new context."
	"Note that starting a new array or object context also requires a new separator."

	| lastContext lastSeparator |
	lastContext := context.
	lastSeparator := separator.
	context := contextCharacter.
	separator := nil.
	[ aNullaryBlock value ]
		ensure: [
			context := lastContext.
			separator := lastSeparator ]! !

!JsonBuilder methodsFor: 'private-encoding' stamp: 'ess 6/24/2025 08:34:41'!
inValueContextDo: aNullaryBlock
	"Save and restore the current context while evaluating aNullaryBlock in a value context."

	self
		inChildContext: nil
		do: aNullaryBlock! !

!JsonBuilder methodsFor: 'private-encoding' stamp: 'ess 6/24/2025 08:39:52'!
writeCollectionBegin: beginCharacter end: endCharacter do: aNullaryBlock
	"Ensure a collection is fenced with the appropriate begin and end characters."

	self requireValueContext.
	self
		inChildContext: beginCharacter
		do: [
			stream nextPut: beginCharacter.
			[ aNullaryBlock value ]
				ensure: [
					stream nextPut: endCharacter ] ]! !

!JsonBuilder methodsFor: 'private-testing' stamp: 'ess 6/24/2025 08:21:43'!
isArrayContext
	"True if we're expecting array elements."

	^ context = $[! !

!JsonBuilder methodsFor: 'private-testing' stamp: 'ess 6/24/2025 08:22:15'!
isObjectContext
	"True if we're expecting object members."

	^ context = ${! !

!JsonBuilder methodsFor: 'private-testing' stamp: 'ess 6/24/2025 08:22:41'!
isValueContext
	"True if we're expecting a JSON value."

	^ context isNil! !

!JsonBuilder class methodsFor: 'accessing' stamp: 'ess 6/24/2025 08:17:23'!
characterEscape: aCharacter

	^ characterEscapes
		at: aCharacter codePoint + 1
		ifAbsent: [ nil ]! !

!JsonBuilder class methodsFor: 'as yet unclassified' stamp: 'ess 6/23/2025 16:04:35'!
stringify: anObject

	^ UnicodeString streamContents: [ :stream |
		self
			write: anObject
			on: stream ]! !

!JsonBuilder class methodsFor: 'as yet unclassified' stamp: 'ess 6/23/2025 16:02:09'!
write: anObject on: aStream

	(self on: aStream)
		writeValue: anObject! !

!JsonBuilder class methodsFor: 'class initialization' stamp: 'ess 6/24/2025 08:16:08'!
initialize
	"
	JsonBuilder initialize
	"

	characterEscapes := Array new: 128.
	(0 to: 31), #(127) do: [ :each |
		| hex |
		hex := each printStringHex
			padded: #left
			to: 4
			with: $0.
		characterEscapes
			at: each + 1
			put: '\u', hex ].
	{	Character backspace	-> '\b'.	"\u0008"
		Character tab			-> '\t'.	"\u0009"
		Character lf				-> '\n'.	"\u000A"
		Character newPage		-> '\f'.	"\u000C"
		Character cr			-> '\r'.	"\u000D"
		$"						-> '\"'.	"\u0022"
		$\						-> '\\'	"\u0052"
	} do: [ :each |
		characterEscapes
			at: each key asciiValue + 1
			put: each value ]! !

!JsonBuilder class methodsFor: 'instance creation' stamp: 'ess 6/23/2025 10:49:26'!
on: aStream

	^ self new
		setStream: aStream! !

!JsonObject methodsFor: 'accessing' stamp: 'ess 6/24/2025 10:38:14'!
at: aKey
	"make it work more like javascript objects"

	^ self
		at: aKey
		ifAbsent: [ nil] ! !

!JsonObject methodsFor: 'accessing' stamp: 'ess 6/24/2025 10:37:41'!
name
	"override 'cause Object defines this"

	^ self at: 'name'! !

!JsonObject methodsFor: 'accessing' stamp: 'ess 6/24/2025 10:37:55'!
value
	"override 'cause Object defines this"

	^ self at: 'value'! !

!JsonObject methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 10:37:06'!
doesNotUnderstand: aMessage

	| key |
	key := aMessage selector.
	key isUnary ifTrue: [
		^ self
			at: key
			ifAbsent: [ nil ] ].
	^ (key isKeyword and: [(key occurrencesOf: $:) = 1])
		ifFalse: [
			super doesNotUnderstand: aMessage ]
		ifTrue: [
			key := key allButLast asSymbol.
			self
				at: key
				put: aMessage arguments first ]! !

!JsonObject class methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 10:36:00'!
fromAssociations: collectionOfAssociations

	| result |
	result := self new.	
	collectionOfAssociations do: [ :each |
		result
			at: each key
			put: each value ].
	^ result! !

!Object methodsFor: '*JSON-converting' stamp: 'ess 6/23/2025 15:58:55'!
asJsonObject
	"Convert this object to a form that can be serialized as JSON."	
	"Most objects cannot easily be serialized as JSON, so the default implementation signals an error.  Boolean, UndefinedObject, Float, Integer, and CharacterSequence are serializable.  A SequenceableCollection can be serialized if its elements are serializable, and a Dictionary can be serialized if its keys are strings and its values are serializable."

	^ JsonDomainError signal! !

!Object methodsFor: '*JSON-converting' stamp: 'ess 6/23/2025 16:51:51'!
asJsonString

	^ Json
		stringify: self! !

!Object methodsFor: '*JSON-writing' stamp: 'ess 6/23/2025 16:00:13'!
buildJson: aJsonBuilder

	self asJsonObject
		buildJson: aJsonBuilder! !

!Object methodsFor: '*JSON-writing' stamp: 'ess 6/23/2025 16:52:51'!
jsonWriteOn: aStream

	Json
		write: self
		on: aStream! !

!Array2D methodsFor: '*JSON-converting' stamp: 'ess 6/23/2025 16:43:50'!
asJsonObject

	^ Array
		streamContents: [ :outer |
			1 to: height do: [ :i |
				outer nextPut:
					(Array
						streamContents: [ :inner |
							1 to: width do: [ :j |
								inner nextPut:
									(self i: i j: j) asJsonObject ] ]
						estimatedSize: width) ] ]
		estimatedSize: height! !

!Array2D methodsFor: '*JSON-writing' stamp: 'ess 6/23/2025 16:44:13'!
buildJson: aJsonBuilder

	aJsonBuilder writeArrayDo: [
		1 to: height do: [ :i |
			aJsonBuilder writeArrayElementDo: [
				aJsonBuilder writeArrayDo: [
					1 to: width do: [ :j |
						aJsonBuilder
							writeArrayElement: (self i: i j: j) ] ] ] ] ]! !

!SequenceableCollection methodsFor: '*JSON-converting' stamp: 'ess 6/23/2025 16:46:09'!
asJsonObject
	"A SequenceableCollection can be serialized as a JSON array if its elements can be serialized."
	"See also Object>>#asJsonObject."

	^ Array
		streamContents: [ :stream |
			self do: [ :each |
				stream
					nextPut: each asJsonObject ] ]
		estimatedSize: self size! !

!SequenceableCollection methodsFor: '*JSON-writing' stamp: 'ess 6/23/2025 16:14:43'!
buildJson: aJsonBuilder

	aJsonBuilder
		writeArray: self! !

!FloatArray methodsFor: '*JSON' stamp: 'jmv 7/11/2018 18:14:09'!
jsonWriteElement: element on: aStream
	"FloatArray elements are answered as 64 bit Float, but are really 32 bit Float.
	When writing to JSON (or printing), print them as 32 bit Float."

	element printAsIEEE32BitPrecisionFloatOn: aStream base: 10! !

!CharacterSequence methodsFor: '*JSON-converting' stamp: 'ess 6/23/2025 15:51:58'!
asJsonObject
	"CharacterSequences serialize directly to JSON as strings."
	"See also Object>>#asJsonObject."

	^ self! !

!CharacterSequence methodsFor: '*JSON-converting' stamp: 'ess 6/23/2025 15:51:32'!
asSnakeCase
	"as_snake_case"
	"A convenience, as snake_case is commonly used for JSON object keys."

	^ self species streamContents: [ :stream |
		self withIndexDo: [ :each :index |
			(index > 1 and: [ each isUppercase ]) ifTrue: [
				stream nextPut: $_ ].
			stream nextPut: each asLowercase ] ]! !

!CharacterSequence methodsFor: '*JSON-writing' stamp: 'ess 6/23/2025 15:54:42'!
buildJson: aJsonBuilder

	aJsonBuilder
		writeString: self! !

!Text methodsFor: '*JSON-converting' stamp: 'ess 6/23/2025 16:11:14'!
asJsonObject

	^ string! !

!Dictionary methodsFor: '*JSON-converting' stamp: 'ess 6/23/2025 16:18:36'!
asJsonObject
	"A Dictionary can be serialized as JSON if its keys are strings and its values are serializable."
	"See also Object>>#asJsonObject."

	| result |
	result := OrderedDictionary new.
	self keysAndValuesDo: [ :key :value |
		result
			at: key asString
			put: value asJsonObject ].
	^ result! !

!Dictionary methodsFor: '*JSON-writing' stamp: 'ess 6/23/2025 16:18:17'!
buildJson: aJsonBuilder

	aJsonBuilder
		writeObject: self! !

!WriteStream methodsFor: '*JSON-printing' stamp: 'cwp 10/25/2006 12:27'!
jsonPrint: anObject
	anObject jsonWriteOn: self! !

!Boolean methodsFor: '*JSON-converting' stamp: 'ess 6/23/2025 15:57:34'!
asJsonObject
	"Booleans serialize directly to JSON as 'true' and 'false'."
	"See also Object>>#asJsonObject."

	^ self! !

!False methodsFor: '*JSON-writing' stamp: 'ess 6/23/2025 15:57:02'!
buildJson: aJsonBuilder

	aJsonBuilder writeFalse! !

!True methodsFor: '*JSON-writing' stamp: 'ess 6/23/2025 15:58:10'!
buildJson: aJsonBuilder

	aJsonBuilder writeTrue! !

!Fraction methodsFor: '*JSON-converting' stamp: 'ess 6/24/2025 10:15:43'!
asJsonObject

	^ self asFloat! !

!Float methodsFor: '*JSON-converting' stamp: 'ess 6/23/2025 16:20:23'!
asJsonObject
	"Floats serialize directly to JSON as numbers."
	"See also Object>>#asJsonObject."

	^ self! !

!Float methodsFor: '*JSON-writing' stamp: 'ess 6/23/2025 16:23:07'!
buildJson: aJsonBuilder

	aJsonBuilder
		writeNumber: self! !

!Integer methodsFor: '*JSON-converting' stamp: 'ess 6/23/2025 16:20:46'!
asJsonObject
	"Integers (between 2^-52 and 2^52-1) serialize directly to JSON as numbers.  (Integers outside this range can also be serialized, but only approximately.)"
	"See also Object>>#asJsonObject."

	^ self! !

!Integer methodsFor: '*JSON-writing' stamp: 'ess 6/23/2025 16:23:12'!
buildJson: aJsonBuilder

	aJsonBuilder
		writeNumber: self! !

!Association methodsFor: '*JSON-writing' stamp: 'ess 6/23/2025 16:26:54'!
buildJson: aJsonBuilder

	aJsonBuilder
		writeObjectKey: key
		value: value! !

!UndefinedObject methodsFor: '*JSON-converting' stamp: 'ess 6/23/2025 16:09:00'!
asJsonObject
	"The UndefinedObject serializes directly to JSON as 'null'."
	"See also Object>>#asJsonObject."

	^ self! !

!UndefinedObject methodsFor: '*JSON-writing' stamp: 'ess 6/23/2025 16:09:37'!
buildJson: aJsonBuilder

	aJsonBuilder writeNull! !

!FileEntry methodsFor: '*json' stamp: 'pb 5/25/2016 01:32'!
jsonContents
	"
	'noesta.json' asFileEntry jsonContents
	"
	^self readStreamDo: [ :stream |
		Json readFrom: stream ]! !
JsonBuilder initialize!
