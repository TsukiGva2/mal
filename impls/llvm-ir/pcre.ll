%pcre = type opaque

@PCRE_ERR = constant [18 x i8] c"PCRE creation err\00"
@PCRE_FMT = constant [17 x i8] c"error at %d: %s\0A\00"

@error = global i8* null
@error_offset = global i32 0

@regex_ptr = global %pcre* null

; This function Dies if it goes wrong
; also you can only have one regex at once
; not like i need much anyway -- FIXME
define %pcre* @Regex(i8* %pattern) {

  ; free global ptr if existing regex
  call void
    @CleanRegex()

  %re = call %pcre*
    @pcre_compile(
      i8* %pattern,
      i32 0,
      i8** @error,
      i32* @error_offset,
      i8* null
  )

  %isNull = icmp eq %pcre* %re, null
  br i1 %isNull, label %die, label %ok

die:
  %1 = load i32, i32* @error_offset
  %2 = load i8*, i8** @error

  call i32 (i8*, ...)
    @printf(
      i8* getelementptr (
        [17 x i8],
        [17 x i8]* @PCRE_FMT,
        i64 0,
        i64 0
      ),
      i32 %1,
      i8* %2
  )

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
  store %pcre* %re, %pcre** @regex_ptr

  ret %pcre* %re
}

define void @CleanRegex() {

  %re = load %pcre*, %pcre** @regex_ptr
  %hasRegex = icmp eq %pcre* %re, null

  br i1 %hasRegex, label %yes, label %no

yes:
  call void
    @FreeRegex()

  ret void
no:
  ret void
}

; ok, this took me a good debugging session...
; PCRE_FREE, is defined at the pcre.h header with the
; following comment above it:

  ; Indirection for store get and free functions. These can be set to
  ; alternative malloc/free functions if required. 

; and i only got this after compiling with clang and getting a lot
; of segfaults, only to finally understand why clang was trying
; to load a function pointer instead of just declaring the function.

; always READ THE DOCS.

@pcre_free = external global void (%pcre*)*

define void @FreeRegex() {

  %re = load %pcre*, %pcre** @regex_ptr

; rookie mistake:
  ;  call void
  ;    @pcre_free(
  ;      %pcre* %re
  ;  )

  %pfree = load void (%pcre*)*, void (%pcre*)** @pcre_free
  call void
    %pfree(%pcre* %re)

  ret void
}

declare i32    @printf(i8*, ...)
declare %pcre* @pcre_compile(i8*,i32,i8**,i32*,i8*)
;declare void   @pcre_free(%pcre*)
declare void   @Die(i8*) noreturn
