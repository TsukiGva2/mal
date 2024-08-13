%FILE = type opaque

@stdin = external global %FILE*

; end definition

@BUFSIZE = private constant i64 255

@BUFFER = private global i8* null

define i8* @NewBuffer() {

  %size = load i64, i64* @BUFSIZE

  %buf = call i8*
    @AllocI8(i64 %size)

  ret i8* %buf
}

define i8* @Readline() {

  %global_buf = load i8*, i8** @BUFFER

  %isNull = icmp eq i8* %global_buf, null

  %WhichBuf = alloca i8*

  br i1 %isNull, label %alloc, label %noalloc

alloc:
  %1 = call i8*
    @NewBuffer()

  store i8* %1, i8** %WhichBuf

  ; setting @BUFFER to newly allocated buf for
  ; reutilization
  store i8* %1, i8** @BUFFER

  br label %continue

noalloc:
  store i8* %global_buf, i8** %WhichBuf

  br label %continue

continue:
  %buf = load i8*, i8** %WhichBuf

  %stdin = load %FILE*, %FILE** @stdin
  %size = load i64, i64* @BUFSIZE

  %result = call i8*
    @fgets(
      i8* %buf,
      i64 %size,
      %FILE* %stdin
  )

  ; returns %buf or NULL in case of EOF or error
  ret i8* %result
}

define void @Freeline(i8* %line) {

  call void
    @FreeI8(i8* %line)

  ret void
}

declare i8* @fgets(i8*, i64, %FILE*)

declare i8*  @AllocI8(i64)
declare void @FreeI8(i8*)

