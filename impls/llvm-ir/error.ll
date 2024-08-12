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

declare void @perror(i8*)
declare void @exit(i32)

