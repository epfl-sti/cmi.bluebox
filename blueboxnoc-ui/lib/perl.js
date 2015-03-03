/**
 * Support for invoking the Perl code within the Blue Box NOC project.
 */
var debug = require('debug')('perl'),
    child_process = require("child_process"),
    runtime = require("./runtime");

var perlCmd = (function () {
    var perlCmd_cached;
    return function perlCmd(opt_set) {
        if (opt_set) {
            perlCmd_cached = opt_set;
        } else if (! perlCmd_cached) {
            perlCmd_cached = process.env.PERL || 'perl';
        }
        return perlCmd_cached;
    }
})();

/**
 * Get the Perl flags. Mutate the returned value to change them.
 */

var perlStdFlags = (function () {
    var perlStdFlags_cached;
    return function perlStdFlags() {
        if (! perlStdFlags_cached) {
            perlStdFlags_cached = ["-w", "-Mstrict",
                "-I" + runtime.srcDir() + "/plumbing/perllib"];
        }
        return perlStdFlags_cached;
    }
})();

/**
 * Run a snippet of Perl and expect a zero exit code.
 *
 * @param perlFlags The flags and arguments to pass to Perl, as an array
 * @param stdin A string to pass to Perl as stdin
 * @param done Callback to be called as done(stdout, errcode, stderr)
 *             or done(stdout), depending on exit code
 */
module.exports.runPerl = function runPerl(perlFlags, stdin, done) {
    var perlProcess = child_process.spawn(
        perlCmd(),
        perlStdFlags().concat(perlFlags));
    var perlOut = '';
    var perlErr = '';
    var perlExitCode;

    perlProcess.stdout.on('data', function(data) {
        perlOut += data;
    });
    perlProcess.stderr.on('data', function(data) {
        process.stderr.write(data);
        perlErr += data;
    });

    var waitingFor = {
        stdoutClosed: 1,
        stderrClosed: 1,
        perlExited: 1
    };

    function doneWaiting(t) {
        debug("doneWaiting(" + t + ")");
        delete waitingFor[t];
        if (Object.keys(waitingFor).length) {
            return;  // Still waiting for something else
        }
        if (perlExitCode == 0) {
            // Perl went well
            done(perlOut);
        } else {
            done(perlOut, perlExitCode, perlErr);
        }
    }

    perlProcess.stdout.on('end', function () {
        doneWaiting("stdoutClosed");
    });
    perlProcess.stderr.on('end', function () {
        doneWaiting("stderrClosed");
    });
    perlProcess.on('exit', function (exitCode) {
        perlExitCode = exitCode;
        doneWaiting("perlExited");
    });
    perlProcess.stdin.write(stdin);
    perlProcess.stdin.end();
};

/**
 * Run a snippet of Perl and expect a JSON string in return.
 *
 * The Perl snippet should exit with status 0 or 4, with 0 meaning success
 * and 4 meaning orderly failure; in these two cases a JSON-encoded string
 * is expected on stdout. In case of success, the callback will be called
 * as done(jsonOut), where jsonOut is the JSON-parsed stdout string.
 * In case of orderly failure, the callback will be called as
 * done(null, jsonOut). In case of disorderly failure, done(null, perlStderr)
 * is called with perlStderr being Perl's stderr as a string. Finally, in case
 * of internal error in talkJSONToPerl (e.g. unable to decode stdout as
 * JSON), done(null, exn) is called with exn being an exception object.
 *
 * @param perlCode A snippet of Perl code to run
 * @param structIn A pure data structure to pass to Perl as JSON
 * @param done Callback to be called as done(null, error) or done(struct),
 *             where struct is JSON-parsed from Perl's stdout as
 *             per above
 * @param opts Options dict
 * @param opts.perlFlags Additional flags to pass to Perl, e.g. -MFoo::Bar
 */
module.exports.talkJSONToPerl = function talkJSONToPerl(
    perlCode, structIn, done, opts) {

    opts = opts || {};
    module.exports.runPerl(
        (opts.perlFlags || []).concat(["-e", perlCode]),
        JSON.stringify(structIn),
        function (perlOut, perlExitCode, perlErr) {
            try {
                if (! perlExitCode) {
                    // Perl went well
                    done(JSON.parse(perlOut));
                } else if (perlExitCode == 4) {
                    // Perl signals an orderly error
                    done(null, JSON.parse(perlOut));
                } else {
                    // Perl just bombed
                    done(null, perlErr)
                }
            } catch (e) {
                // Something else went awry, e.g. bad JSON on stdout
                done(null, e);
            }
        });
};
