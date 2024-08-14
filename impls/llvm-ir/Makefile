
STEPS = step0_repl step1_read_print step2_eval step3_env step4_if_fn_do step5_tco step6_file step7_quote step8_macros step9_try stepA_mal

COMPONENTS = error.o allocator.o readline.o pcre.o linkedlist.o

LIB = -lpcre

all: $(COMPONENTS) $(STEPS)

%.o: %.ll
	llc -filetype=obj $<

%: %.o $(COMPONENTS)
	# using clang as a linker
	clang -o $@ $(COMPONENTS) $< $(LIB)

.PHONY: clean
clean:
	rm -f $(COMPONENTS)
	rm -f $(STEPS) $(STEPS:%=%.o)
