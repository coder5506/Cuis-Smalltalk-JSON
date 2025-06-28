# Cuis-Smalltalk-JSON

Includes a fix for better Unicode support.

Not that there was a bug in the core JSON, per se.
When it was originally written, the necessary Unicode support was not available in the image.

Also provides one extension method `Object>>asJsonObject` to convert an object to a form that is easily serialized as JSON,
because that is sometimes more convenient than serializing directly to JSON.

That's it.

## License

[MIT License](LICENSE)

## Dependencies

[Cuis-Smalltalk-Unicode](https://github.com/coder5506/Cuis-Smalltalk-Unicode)
