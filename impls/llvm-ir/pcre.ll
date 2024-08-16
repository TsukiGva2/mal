%pcre = type opaque

@PCRE_ERR     = constant [18 x i8] c"PCRE creation err\00"
@PCRE_ERR_FMT = constant [17 x i8] c"error at %d: %s\0A\00"

@Error        = global i8* null
@Error.offset = global i32 0

@Pattern      = global %pcre* null
@Regex.Groups = global [10 x i32] zeroinitializer

define void @Regex.Err() noreturn {
  ; Reporting the pcre error

  %1 = load i32, i32* @Error.offset
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
}

define void @Regex.Init(i8* %pattern) {

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

  br i1 %isNullOrError, label %err, label %ok

err:
  ; simply die with a msg

  call void
    @Regex.Err() noreturn

  unreachable

ok:
  ; storing new @Pattern in global memory

  store %pcre* %re, %pcre** @Pattern

  ; It's just an object
  ret void
}

define void @Regex.CheckReturnCode(i32 %returnCode) {

  %isPcreError = icmp ne i32 %returnCode, -1 ; NOMATCH
  br i1 %isPcreError, label %err, label %ok

err:
  ; die if actual regex error

  store i32 %returnCode, i32* @Error.offset

  call void
    @Regex.Err() noreturn

  unreachable

ok:
  ; don't report if it just didn't match

  ret void
}

;--DEBUG--
;; Lengthy function for debugging
;@PCRE_DBG_FMT = constant [26 x i8] c"Group: %d, Bounds: %d-%d\0A\00"
;define void @Regex.Inspect() {
;  %pf1 = getelementptr
;    [10 x i32],
;    [10 x i32]* @Regex.Groups,
;    i64 0,
;    i64 0
;  %pf2 = getelementptr
;    [10 x i32],
;    [10 x i32]* @Regex.Groups,
;    i64 0,
;    i64 1
;  %ps1 = getelementptr
;    [10 x i32],
;    [10 x i32]* @Regex.Groups,
;    i64 0,
;    i64 2
;  %ps2 = getelementptr
;    [10 x i32],
;    [10 x i32]* @Regex.Groups,
;    i64 0,
;    i64 3

;  %f1 = load i32, i32* %pf1
;  %f2 = load i32, i32* %pf2
;  %s1 = load i32, i32* %ps1
;  %s2 = load i32, i32* %ps2

;  call i32 (i8*, ...)
;    @printf(
;      i8* getelementptr (
;        [26 x i8],
;        [26 x i8]* @PCRE_DBG_FMT,
;        i64 0,
;        i64 0
;      ),
;      i32 1,
;      i32 %f1,
;      i32 %f2
;  )
;  call i32 (i8*, ...)
;    @printf(
;      i8* getelementptr (
;        [26 x i8],
;        [26 x i8]* @PCRE_DBG_FMT,
;        i64 0,
;        i64 0
;      ),
;      i32 2,
;      i32 %s1,
;      i32 %s2
;  )

;  ret void
;}
;--END--

; Returns the result of pcre_exec
; i.e. the number of groups
define i32 @Regex.Match(i8* %str) {

  %length = call i32
    @strlen(i8* %str)

  %pattern = load %pcre*, %pcre** @Pattern

  %result = call i32
    @pcre_exec(
      %pcre* %pattern,
      i8* null,
      i8* %str,
      i32 %length,
      i32 0,
      i32 0,

      ; Array of substring indexes
      i32* getelementptr (
        [10 x i32],
        [10 x i32]* @Regex.Groups,
        i64 0,
        i64 0
      ),

      ; size of the array
      i32 10
  )

  ; %1 >= 0?
  %didMatch = icmp sge i32 %result, 0
  br i1 %didMatch, label %match, label %err

match:
  br label %done

err:
  call void
    @Regex.CheckReturnCode(i32 %result)

  br label %done

done:
  ret i32 %result
}

define i32 @Regex.GetCaptureBegin() {

  ; get start of second group (first '('')' capture)
  %startPtr = getelementptr
    [10 x i32],
    [10 x i32]* @Regex.Groups,
    i64 0,
    i64 2   ; start of second group substring

  %start = load i32, i32* %startPtr

  ret i32 %start
}

define i32 @Regex.GetCaptureEnd() {

  ; get end of second group (first '('')' capture)
  %endPtr = getelementptr
    [10 x i32],
    [10 x i32]* @Regex.Groups,
    i64 0,
    i64 3   ; end of second group substring

  %end = load i32, i32* %endPtr

  ret i32 %end
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

declare i32    @printf(i8*, ...)
declare i32    @strlen(i8*)

declare %pcre* @pcre_compile(i8*, i32, i8**, i32*, i8*)
declare i32    @pcre_exec(%pcre*, i8*, i8*, i32, i32, i32, i32*, i32)
;declare void  @pcre_free(%pcre*)

declare void   @Die(i8*) noreturn

