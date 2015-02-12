module Homework

using Interact, Reactive
using JSON, Requests

display(MIME"text/html"(),
    """<script>$(readall(Pkg.dir("Homework", "src", "homework.js")))</script>""")

function script(expr)
    display(MIME"text/html"(), string("<script>", expr, "</script>"))
end

function configure(key)
    script(string("Homework.config = ", JSON.json(key)))
end

alert(level, text) =
    "<div class='alert alert-$level'>$text</div>"

teeprint(x) = begin println(x); x end # A useful debugging function

function evaluate(config_json, question_no, cookie, answer)
    # TODO: warn if user id / problem set is invalid,
    # do whatever and decide the answer
    # display a result (correct / not)
    # display a button that allows user to submit the answer
    config = JSON.parse(config_json)
    if !haskey(config, "host")
        config["host"] = "http://ec2-54-204-24-92.compute-1.amazonaws.com"
    end

    @assert haskey(config, "course")
    @assert haskey(config, "problem_set")

    info = Input("<div class='alert alert-info'>Evaluating the answer...</div>")

    # The HTTP requests to evaluate answer goes here...
    # After the request, you can push the
    @async push!(info, alert("info", "Verifying your answer..."))
    res = Requests.get(string(strip(config["host"], ['/']), "/hw/");
            query = ["mode" => "check",
                     "course" => config["course"],
                     "problemset" => config["problem_set"],
                     "question" => question_no,
                     "answer" => JSON.json(answer)],
            headers = ["Cookie" => cookie])

    show_btn = false
    if res.status == 200
        result = res.data |> JSON.parse
        if result["code"] != 0
            @async push!(info, alert("danger", "Something went wrong while verifying your code!"))
        else
            if result["data"] == 1
                @async push!(info, alert("success", "That is the correct answer!"))
                submit(config, question_no, cookie, answer, info)
            else
                @async push!(info, alert("warning", "That answer is wrong! You may try again."))
                show_btn = true
            end
        end
    else
        @async push!(info, alert("danger", "There was an unexpected error while accessing the homework server."))
    end

    b = button("Submit answer anyway...")
    lift(_ -> submit(config, question_no, cookie, answer, info), b, init=nothing)

    display(lift(html, info))
    if show_btn
        display(b)
    end
    # return the answer itself for consistency
    answer
end

function submit(config, question_no, cookie, answer, info)
    # TODO: confirm this as the answer
    @async begin
        # The HTTP requests to evaluate answer goes here...
        # After the request, you can push the
    res = Requests.get(string(strip(config["host"], ['/']), "/hw/");
            query = ["mode" => "submit",
                     "course" => config["course"],
                     "problemset" => config["problem_set"],
                     "question" => question_no,
                     "answer" => JSON.json(answer)],
            headers = ["Cookie" => cookie])

        if res.status == 200
            result = res.data |> JSON.parse
            if result["code"] != 0
                push!(info, alert("danger", "Something went wrong while submitting your answer!"))
            else
                if result["data"] == 1
                    push!(info, alert("success", "Success! Your answer is correct and has been recorded!"))
                else
                    push!(info, alert("warning", "Your answer has been recorded, however it seems to be wrong. You may try again!"))
                end
            end
        else
            push!(info, alert("danger", "There was an unexpected error while accessing the homework server."))
        end
    end
end

end # module
