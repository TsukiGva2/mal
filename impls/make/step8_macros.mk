#
# mal (Make Lisp)
#
_TOP_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(_TOP_DIR)types.mk
include $(_TOP_DIR)reader.mk
include $(_TOP_DIR)printer.mk
include $(_TOP_DIR)env.mk
include $(_TOP_DIR)core.mk

SHELL := /bin/bash
INTERACTIVE ?= yes
EVAL_DEBUG ?=

# READ: read and parse input
define READ
$(if $(READLINE_EOF)$(__ERROR),,$(call READ_STR,$(if $(1),$(1),$(call READLINE,"user> "))))
endef

# EVAL: evaluate the parameter

# elt, accumulator list -> new accumulator list
QQ_LOOP = $(call _list,\
  $(if $(and $(_list?),$(call _EQ,splice-unquote,$($(sfirst)_value))),\
    $(call _symbol,concat) $(call _nth,$1,1),\
    $(call _symbol,cons) $(QUASIQUOTE))\
  $2)

# list or vector source -> right folded list
QQ_FOLD = $(if $(_empty?),$(call _list,),$(call QQ_LOOP,$(sfirst),$(call QQ_FOLD,$(srest))))

QUASIQUOTE = $(strip \
  $(if $(_list?),                $(if $(call _EQ,unquote,$($(sfirst)_value)),\
                                   $(call _nth,$1,1),\
                                   $(QQ_FOLD)),\
  $(if $(_vector?),              $(call _list,$(call _symbol,vec) $(QQ_FOLD)),\
  $(if $(_symbol?)$(_hash_map?), $(call _list,$(call _symbol,quote) $1),\
                                 $1))))
define LET
$(strip \
  $(word 1,$(2) \
    $(foreach var,$(call _nth,$(1),0),\
      $(foreach val,$(call _nth,$(1),1),\
        $(call ENV_SET,$(2),$($(var)_value),$(call EVAL,$(val),$(2)))\
        $(foreach left,$(call srest,$(call srest,$(1))),
          $(if $(call _EQ,0,$(call _count,$(left))),\
            ,\
            $(call LET,$(left),$(2))))))))
endef

define EVAL_INVOKE
$(if $(__ERROR),,\
  $(and $(EVAL_DEBUG),$(info EVAL_INVOKE: $(call _pr_str,$(1))))
  $(foreach a0,$(call _nth,$(1),0),\
    $(if $(call _EQ,def!,$($(a0)_value)),\
      $(foreach a1,$(call _nth,$(1),1),\
        $(foreach a2,$(call _nth,$(1),2),\
          $(foreach res,$(call EVAL,$(a2),$(2)),\
            $(if $(__ERROR),,\
              $(if $(call ENV_SET,$(2),$($(a1)_value),$(res)),$(res),))))),\
    $(if $(call _EQ,let*,$($(a0)_value)),\
      $(foreach a1,$(call _nth,$(1),1),\
        $(foreach a2,$(call _nth,$(1),2),\
          $(call EVAL,$(a2),$(call LET,$(a1),$(call ENV,$(2)))))),\
    $(if $(call _EQ,quote,$($(a0)_value)),\
      $(call _nth,$(1),1),\
    $(if $(call _EQ,quasiquote,$($(a0)_value)),\
      $(call EVAL,$(call QUASIQUOTE,$(call _nth,$(1),1)),$(2)),\
    $(if $(call _EQ,defmacro!,$($(a0)_value)),\
      $(foreach a1,$(call _nth,$(1),1),\
        $(foreach a2,$(call _nth,$(1),2),\
          $(foreach res,$(call _clone_obj,$(call EVAL,$(a2),$(2))),\
            $(eval _macro_$(res) = true)\
            $(if $(call ENV_SET,$(2),$($(a1)_value),$(res)),$(res),)))),\
    $(if $(call _EQ,do,$($(a0)_value)),\
      $(call slast,$(call _smap,EVAL,$(call srest,$(1)),$(2))),\
    $(if $(call _EQ,if,$($(a0)_value)),\
      $(foreach a1,$(call _nth,$(1),1),\
        $(foreach a2,$(call _nth,$(1),2),\
          $(foreach cond,$(call EVAL,$(a1),$(2)),\
            $(if $(or $(call _EQ,$(__nil),$(cond)),$(call _EQ,$(__false),$(cond))),\
              $(foreach a3,$(call _nth,$(1),3),$(call EVAL,$(a3),$(2))),\
              $(call EVAL,$(a2),$(2)))))),\
    $(if $(call _EQ,fn*,$($(a0)_value)),\
      $(foreach a1,$(call _nth,$(1),1),\
        $(foreach a2,$(call _nth,$(1),2),\
          $(call _function,$$(call EVAL,$(a2),$$(call ENV,$(2),$(a1),$$1))))),\
    $(foreach f,$(call EVAL,$(a0),$(2)),\
      $(foreach args,$(call srest,$(1)),\
        $(if $(_macro_$(f)),\
          $(call EVAL,$(call apply,$(f),$(args)),$(2)),\
          $(call apply,$(f),$(call _smap,EVAL,$(args),$(2))))))))))))))))
endef

define EVAL
$(strip $(if $(__ERROR),,\
  $(if $(filter-out false nil,$(call _obj_type,$(or $(call ENV_GET,$(2),DEBUG-EVAL),$(__nil)))),\
    $(info EVAL: $(_pr_str)))\
  $(if $(call _symbol?,$(1)),\
    $(foreach key,$($(1)_value),\
      $(or $(call ENV_GET,$(2),$(key)),\
           $(call _error,'$(key)' not found)$(__nil))),\
  $(if $(call _vector?,$(1)),\
    $(call _smap_vec,EVAL,$(1),$(2)),\
  $(if $(call _hash_map?,$(1)),\
    $(foreach new_hmap,$(call __new_obj,hmap),\
      $(foreach v,$(call __get_obj_values,$(1)),\
        $(eval $(v:$(1)_%=$(new_hmap)_%) := $(call EVAL,$($(v)),$(2))))\
      $(eval $(new_hmap)_size := $($(1)_size))\
      $(new_hmap)),\
  $(if $(call _list?,$(1)),\
    $(if $(call _EQ,0,$(call _count,$(1))),\
      $(1),\
      $(word 1,$(strip $(call EVAL_INVOKE,$(1),$(2)) $(__nil)))),\
    $(1)))))))
endef


# PRINT:
define PRINT
$(if $(__ERROR),Error: $(call _pr_str,$(__ERROR),yes),$(if $(1),$(call _pr_str,$(1),yes)))$(if $(__ERROR),$(eval __ERROR :=),)
endef

# REPL:
REPL_ENV := $(call ENV)
REP = $(call PRINT,$(strip $(call EVAL,$(strip $(call READ,$(1))),$(REPL_ENV))))
REPL = $(info $(call REP,$(call READLINE,"user> ")))$(if $(READLINE_EOF),,$(call REPL))

# core.mk: defined using Make
_fref = $(eval REPL_ENV := $(call ENV_SET,$(REPL_ENV),$(1),$(call _function,$$(call $(2),$$1))))
_import_core = $(if $(strip $(1)),$(call _fref,$(word 1,$(1)),$(word 2,$(1)))$(call _import_core,$(wordlist 3,$(words $(1)),$(1))),)
$(call _import_core,$(core_ns))
REPL_ENV := $(call ENV_SET,$(REPL_ENV),eval,$(call _function,$$(call EVAL,$$(1),$$(REPL_ENV))))
_argv := $(call _list)
REPL_ENV := $(call ENV_SET,$(REPL_ENV),*ARGV*,$(_argv))

# core.mal: defined in terms of the language itself
$(call do,$(call REP, (def! not (fn* (a) (if a false true))) ))
$(call do,$(call REP, (def! load-file (fn* (f) (eval (read-string (str "(do " (slurp f) "\nnil)"))))) ))
$(call do,$(call REP, (defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw "odd number of forms to cond")) (cons 'cond (rest (rest xs))))))) ))

# Load and eval any files specified on the command line
$(if $(MAKECMDGOALS),\
  $(foreach arg,$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)),\
    $(call do,$(call _conj!,$(_argv),$(call _string,$(arg)))))\
  $(call do,$(call REP, (load-file "$(word 1,$(MAKECMDGOALS))") )) \
  $(eval INTERACTIVE :=),)

# repl loop
$(if $(strip $(INTERACTIVE)),$(call REPL))

.PHONY: none $(MAKECMDGOALS)
none $(MAKECMDGOALS):
	@true
