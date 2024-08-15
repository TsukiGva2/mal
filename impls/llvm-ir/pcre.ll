%pcre = type opaque

@PCRE_ERR     = constant [18 x i8] c"PCRE creation err\00"
@PCRE_ERR_FMT = constant [17 x i8] c"error at %d: %s\0A\00"

@Error        = global i8* null
@Error.offset = global i32 0

@Pattern = global %pcre* null

define %pcre* @Regex.Init(i8* %pattern) {

  ; Compiles the given %pattern and
  ; deals with errors accordingly

  ; this function Dies if it goes wrong,
  ; for simplicity.

  call void
    @Regex.Clean()

  %re = call %pcre*
    @pcre_compile(
      i8* %pattern,
      i32 0,
      i8** @Error,
      i32* @Error.offset,
      i8* null
  )

  br label %validate

validate:
  %error = load i8*, i8** @Error

  %isNull = icmp eq %pcre* %re, null
  %hasError = icmp ne i8* %error, null

  %isNullOrError = or i1 %isNull, %hasError

  br i1 %isNullOrError, label %die, label %ok

die:
  ; Reporting the pcre error

  %1 = load i32, i32* @Error.offset

  ; yes i know it's already loaded, just being consistent
  %2 = load i8*, i8** @Error

  ; "error at {@Error.offset}: {@Error}\n"
  call i32 (i8*, ...)
    @printf(
      i8* getelementptr (
        [17 x i8],
        [17 x i8]* @PCRE_ERR_FMT,
        i64 0,
        i64 0
      ),
      i32 %1,
      i8* %2
  )

  ; die with message: "PCRE Creation err"
  call void
    @Die(i8* getelementptr (
      [18 x i8],
      [18 x i8]* @PCRE_ERR,
      i64 0,
      i64 0
    )
  ) noreturn

  unreachable

ok:
  ; storing new @Pattern in global memory

  store %pcre* %re, %pcre** @Pattern

  ret %pcre* %re
}

define void @Regex.Clean() {

  %re = load %pcre*, %pcre** @Pattern
  %hasRegex = icmp eq %pcre* %re, null

  br i1 %hasRegex, label %clean, label %done

clean:
  call void
    @Pattern.Destruct()

  br label %done

done:
  ret void
}

@pcre_free = external global void (%pcre*)*

define void @Pattern.Destruct() {

  ; Free the current @Pattern, this function is
  ; designed for internal usage only

  %re = load %pcre*, %pcre** @Pattern

  ; this segfaults:
    ;  call void
    ;    @pcre_free(
    ;      %pcre* %re
    ;  )

  ; Why?, well, this took me a good debugging session...

  ; @pcre_free, is defined at the pcre.h header with the
  ; following comment above it:

    ; Indirection for store get and free functions. These can be set to
    ; alternative malloc/free functions if required. 

  ; i only thought about checking the source when i tried to
  ; cheat a little bit (using clang -S -emit-llvm) to know what
  ; was causing pcre_free to segfault. Clang emitted
  ; the indirection you see below, so i got curious as to why
  ; it was trying to do this instead of just calling the function.

  ; always read the code/docs, it will save you time!.

  %pfree = load void (%pcre*)*, void (%pcre*)** @pcre_free
  call void
    %pfree(%pcre* %re)

  ret void
}

;declare void  @pcre_free(%pcre*)

declare i32    @printf(i8*, ...)
declare %pcre* @pcre_compile(i8*,i32,i8**,i32*,i8*)
declare void   @Die(i8*) noreturn
