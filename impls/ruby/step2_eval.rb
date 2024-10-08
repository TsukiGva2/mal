require_relative "mal_readline"
require_relative "types"
require_relative "reader"
require_relative "printer"

# read
def READ(str)
    return read_str(str)
end

# eval
def EVAL(ast, env)
    #puts "EVAL: #{_pr_str(ast, true)}"

    case ast
        when Symbol
            raise "'" + ast.to_s + "' not found" if not env.key? ast
            return env[ast]
        when List   
        when Vector
            return Vector.new ast.map{|a| EVAL(a, env)}
        when Hash
            new_hm = {}
            ast.each{|k,v| new_hm[k] = EVAL(v, env)}
            return new_hm
        else 
            return ast
    end

    # apply list
    if ast.empty?
        return ast
    end

    f = EVAL(ast[0], env)
    args = ast.drop(1)
    return f[*args.map{|a| EVAL(a, env)}]
end

# print
def PRINT(exp)
    return _pr_str(exp, true)
end

# repl
repl_env = {}
REP = lambda {|str| PRINT(EVAL(READ(str), repl_env)) }

repl_env[:+] = lambda {|a,b| a + b}
repl_env[:-] = lambda {|a,b| a - b}
repl_env[:*] = lambda {|a,b| a * b}
repl_env[:/] = lambda {|a,b| a / b}

# repl loop
while line = _readline("user> ")
    begin
        puts REP[line]
    rescue Exception => e
        puts "Error: #{e}" 
        puts "\t#{e.backtrace.join("\n\t")}"
    end
end
