'From Cuis7.5 [latest update: #7279] on 24 June 2025 at 11:21:08 am'!
'Description '!
!provides: 'Tests-JSON' 1 7!
!requires: 'JSON' 1 30 nil!
SystemOrganization addCategory: #'Tests-JSON'!


!classDefinition: #JsonDummyTestObject category: #'Tests-JSON'!
Object subclass: #JsonDummyTestObject
	instanceVariableNames: 'a b c'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tests-JSON'!
!classDefinition: 'JsonDummyTestObject class' category: #'Tests-JSON'!
JsonDummyTestObject class
	instanceVariableNames: ''!

!classDefinition: #JsonExtensionsTests category: #'Tests-JSON'!
TestCase subclass: #JsonExtensionsTests
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tests-JSON'!
!classDefinition: 'JsonExtensionsTests class' category: #'Tests-JSON'!
JsonExtensionsTests class
	instanceVariableNames: ''!

!classDefinition: #JsonTests category: #'Tests-JSON'!
TestCase subclass: #JsonTests
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tests-JSON'!
!classDefinition: 'JsonTests class' category: #'Tests-JSON'!
JsonTests class
	instanceVariableNames: ''!


!JsonTests commentStamp: '<historical>' prior: 0!
I provide a number of test cases for class Json.!

!JsonDummyTestObject methodsFor: 'accessing' stamp: 'ess 6/24/2025 10:54:58'!
a

	^ a! !

!JsonDummyTestObject methodsFor: 'accessing' stamp: 'ess 6/24/2025 10:55:04'!
a: anObject

	a := anObject! !

!JsonDummyTestObject methodsFor: 'accessing' stamp: 'ess 6/24/2025 10:55:09'!
b

	^ b! !

!JsonDummyTestObject methodsFor: 'accessing' stamp: 'ess 6/24/2025 10:55:14'!
b: anObject

	b := anObject! !

!JsonDummyTestObject methodsFor: 'accessing' stamp: 'ess 6/24/2025 10:55:20'!
c

	^ c! !

!JsonDummyTestObject methodsFor: 'accessing' stamp: 'ess 6/24/2025 10:55:25'!
c: anObject

	c := anObject! !

!JsonDummyTestObject methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 10:55:41'!
= other

	^ other class == self class and: [
		a = other a and: [
		b = other b and: [
		c = other c ] ] ]! !

!JsonDummyTestObject methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 10:56:02'!
jsonWriteOn: s

	Json
		renderInstanceVariables: {#a. #b. #c}
		of: self
		on: s! !

!JsonDummyTestObject class methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 10:54:38'!
constructFromJson: j

	^ self new
		a: (j at: 'a');
		b: (j at: 'b');
		c: (j at: 'c');
		yourself! !

!JsonExtensionsTests methodsFor: 'tests' stamp: 'ess 6/24/2025 11:08:42'!
testBoolean
	"Booleans serialize as 'false' or 'true'."

	#(false true) do: [ :each |
		self
			assert: each asJsonObject
			equals: each ]! !

!JsonExtensionsTests methodsFor: 'tests' stamp: 'ess 6/24/2025 11:08:52'!
testCharacterSequence
	"CharacterSequences serialize as JSON strings."

	self
		assert: 'string' asJsonObject
		equals: 'string'! !

!JsonExtensionsTests methodsFor: 'tests' stamp: 'ess 6/24/2025 11:11:18'!
testDictionary
	"Dictionaries serialize as JSON objects, given appropriate keys and values."

	| dict |
	dict := { 'one' -> 1. 'two' -> 2 } asDictionary.
	self
		assert: dict asJsonObject
		equals: dict.
	self
		assert: Dictionary new asJsonObject
		equals: Dictionary new! !

!JsonExtensionsTests methodsFor: 'tests' stamp: 'ess 6/24/2025 11:11:26'!
testDictionaryValueError
	"Dictionary values must be serializable."

	self
		should: [
			{ 'an' -> Object new } asDictionary asJsonObject
		]
		raise: JsonDomainError! !

!JsonExtensionsTests methodsFor: 'tests' stamp: 'ess 6/24/2025 11:09:50'!
testNumber
	"Integers and Floats serialize as JSON numbers."

	#(1 3.14) do: [ :each |
		self
			assert: each asJsonObject
			equals: each ]! !

!JsonExtensionsTests methodsFor: 'tests' stamp: 'ess 6/24/2025 11:10:03'!
testObjectError
	"Objects do not generally serialize."

	self
		should: [
			Object new asJsonObject
		]
		raise: JsonDomainError! !

!JsonExtensionsTests methodsFor: 'tests' stamp: 'ess 6/24/2025 11:10:20'!
testSequenceableCollection
	"Sequences serialize as JSON arrays, given appropriate elements."

	self
		assert: #(1 2 3) asJsonObject
		equals: #(1 2 3).
	self
		assert: #() asJsonObject
		equals: #()! !

!JsonExtensionsTests methodsFor: 'tests' stamp: 'ess 6/24/2025 11:10:39'!
testSequenceableCollectionError
	"The elements of a serializable sequence must also be serializable."

	self
		should: [
			{ Object new. Set new } asJsonObject
		]
		raise: JsonDomainError! !

!JsonExtensionsTests methodsFor: 'tests' stamp: 'ess 6/24/2025 11:10:51'!
testSnakeCase

	#('test_snake_case' 'testSnakeCase' 'TestSnakeCase') do: [:each |
		self
			assert: each asSnakeCase
			equals: 'test_snake_case' ]! !

!JsonExtensionsTests methodsFor: 'tests' stamp: 'ess 6/24/2025 11:11:00'!
testUndefinedObject
	"UndefinedObject serializes as 'null'."

	self
		assert: nil asJsonObject
		equals: nil! !

!JsonTests methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 11:11:58'!
json: aString equals: aValue

	| readValue |
	readValue := self readFrom: aString.
	self
		assert: readValue
		equals: aValue! !

!JsonTests methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 11:13:38'!
readFrom: aString

	^ (Json newWithConstructors: { JsonDummyTestObject })
		readFrom: aString readStream! !

!JsonTests methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 11:12:18'!
render: anObject equals: aString

	self
		assert: (Json render: anObject)
		equals: aString! !

!JsonTests methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 10:57:04'!
simpleDummyObject

	^ JsonDummyTestObject new
		a: 1;
		b: 2;
		c: 3;
		yourself! !

!JsonTests methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 11:13:02'!
testArray

	self
		json: '[]'
		equals: #().
	self
		json: '[[]]'
		equals: #(#()).
	self
		json: '[[], []]'
		equals: #(#() #()).
	self
		json: '["hi", "there"]'
		equals: #('hi' 'there').
	self
		json: '[["a", "b", null]]'
		equals: #(('a' 'b' nil))! !

!JsonTests methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 11:14:24'!
testAtomFalse

	#('false' '  false' 'false  ' '  false  ') do: [ :each |
		self
			json: each
			equals: false ]! !

!JsonTests methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 11:14:52'!
testAtomNull

	#('null' '  null' 'null  ' '  null  ') do: [ :each |
		self
			json: each
			equals: nil ]! !

!JsonTests methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 11:15:25'!
testAtomNumber

	self
		json: '1'
		equals: 1.
	self
		json: '0123'
		equals: 123.
	self
		json: '1.23e2'
		equals: 123.
	self
		json: '-1'
		equals: -1.
	self
		json: '-0'
		equals: 0.
	self
		json: '[-1.2]'
		equals: #(-1.2)! !

!JsonTests methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 11:16:04'!
testAtomSpecialFloats

	| read |

	read := self readFrom: 'NaN'.
	self assert: read isNaN.

	read := self readFrom: 'Infinity'.
	self
		assert: read
		equals: Float infinity.

	read := self readFrom: '-Infinity'.
	self
		assert: read
		equals: Float negativeInfinity! !

!JsonTests methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 11:17:04'!
testAtomString

	self
		json: '"hi"'
		equals: 'hi'.
	self
		json: '"\""'
		equals: '"'.
	self
		json: '"\\"'
		equals: '\'.
	self
		json: '""'
		equals: ''.
	self
		json: '"a\u0004b"'
		equals: ({ $a. Character codePoint: 4. $b } as: String).
	self
		json: '"a\nb"'
		equals: ({ $a. Character lf. $b } as: String)! !

!JsonTests methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 11:17:27'!
testAtomTrue

	#('true' '  true' 'true  ' '  true  ') do: [ :each |
		self
			json: each
			equals: true ]! !

!JsonTests methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 11:17:44'!
testCtor

	self
		json: '@JsonDummyTestObject {"a": 1, "b": 2, "c": 3}'
		equals: self simpleDummyObject.
	self
		json: (Json render: self simpleDummyObject)
		equals: self simpleDummyObject! !

!JsonTests methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 11:18:56'!
testDictionary

	self
		json: '{}'
		equals:
			(JsonObject new).
	self
		json: '{"a": "a"}'
		equals:
			(JsonObject new
				at: 'a' put: 'a';
				yourself).
	self
		json: '{"a": [[]]}'
		equals:
			(JsonObject new
				at: 'a' put: #(#());
				yourself).
	self
		json: '{"a":"b", "b":"a"}'
		equals:
			(JsonObject new
				add: 'a'->'b';
				add: 'b'->'a';
				yourself)! !

!JsonTests methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 11:19:04'!
testMissingCtor

	self 
		should: [
			self readFrom: '@Missing[]'
		]
		raise: JsonSyntaxError! !

!JsonTests methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 11:19:18'!
testMissingCtorNoMap

	self 
		should: [
			Json new
				readFrom: '@Missing[]' readStream
		]
		raise: JsonSyntaxError! !

!JsonTests methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 11:19:44'!
testStringWithUnicode

	| unicodeString |
	unicodeString := UnicodeString with: (Character codePoint: 16r263A).
	self
		json: '"\u263A"'
		equals: unicodeString.
	self
		json: '"', unicodeString, '"'
		equals: unicodeString.
	self
		render: unicodeString
		equals: '"', unicodeString, '"'! !

!JsonTests methodsFor: 'as yet unclassified' stamp: 'ess 6/24/2025 11:20:37'!
testWriteString

	self
		render: '"'
		equals: '"\""'.
	self
		render: '\'
		equals: '"\\"'.
	self
		render: 'hi'
		equals: '"hi"'.
	self
		render: ({ $a. Character lf. $b } as: String)
		equals: '"a\nb"'.
	self
		render: ({ $a. Character codePoint: 4. $b } as: String)
		equals: '"a\u0004b"'.
	self
		render: 'agüita'
		equals: '"agüita"'.
	self
		render: 'ñandú'
		equals: '"ñandú"'! !
