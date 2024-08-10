target triple = "x86_64-pc-linux-gnu"

; STDIN

; defining the stdin IO_FILE structure
%struct._IO_FILE = type {
  i32, ; flags
  i8*, ; _IO_read_ptr
  i8*, ; _IO_read_end
  i8*, ; _IO_read_base
  i8*, ; _IO_write_base
  i8*, ; _IO_write_ptr
  i8*, ; _IO_write_end
  i8*, ; _IO_buf_base
  i8*, ; _IO_buf_end
  i8*, ; _IO_save_base
  i8*, ; _IO_backup_base
  i8*, ; _IO_save_end

  %struct._IO_marker*,
  %struct._IO_FILE*,

  i32,
  i32,
  i64,
  i16,
  i8,
  [1 x i8],
  i8*,
  i64,

  %struct._IO_codecvt*,
  %struct._IO_wide_data*,
  %struct._IO_FILE*,

  i8*,
  i64,
  i32,
  [20 x i8]
}

%struct._IO_marker = type opaque
%struct._IO_codecvt = type opaque
%struct._IO_wide_data = type opaque

@stdin = external global %struct._IO_FILE*
; end definition








@BUFSIZE = constant i64 255



; #DEFINE BUFSIZE 255

; improve alloc logic
define i8* @AllocI8(i64 %size) {
  %ptr = call noalias i8*
    @malloc(i64 %size)

  ret i8* %ptr
}

define i32 @Read() {

  %size = load i64, i64* @BUFSIZE

  %buf = call i8*
    @AllocI8(i64 %size)

  %stdin = load %struct._IO_FILE*, %struct._IO_FILE** @stdin

  call i8*
    @fgets(
      i8* %buf,
      i64 %size,
      %struct._IO_FILE* %stdin
  )

  ; repeating?
  ;%6 = getelementptr [10 x i8], [10 x i8]* %2, i64 0, i64 0
  call i32
    @puts(i8* %buf)

  call void
    @free(i8* %buf)

  ret i32 0
}

define i8 @Eval() {
  ret i8 0
}

define void @Print() {
  ret void
}

define i32 @main() {

  call i32 @Read()

  ret i32 0
}

declare i32 @puts(i8*)
declare i8* @fgets(i8*, i64, %struct._IO_FILE*)

declare noalias i8* @malloc(i64)
declare void @free(i8*)
