define void @Die(i8* %err) noreturn {

  call void
    @perror(
      i8* %err
  )

  call void
    @exit(
      i32 1
  ) noreturn

  unreachable
}

; used frequently enough to be a function
@UNEXPECTED_EOF = constant [16 x i8] c"Unexpected EOF!\00"
define void @UnexpectedEOF() {
  call void
    @Die(
      i8* getelementptr (
        [16 x i8],
        [16 x i8]* @UNEXPECTED_EOF,
        i64 0,
        i64 0
      )
  ) noreturn

  unreachable
}

declare void @perror(i8*)
declare void @exit(i32)

