/**
 * @preserve
 * Copyright (C) 2012 Kyo Nagashima <kyo@hail2u.net>
 *
 * http://hail2u.mit-license.org/2012
 */


/**
 * @fileoverview
 * Registers a language handler for Vim script.
 *
 *
 * To use, include prettify.js and this file in your HTML page.
 * Then put your code in an HTML tag like
 *      <pre class="prettyprint lang-vim"></pre>
 *
 *
 * @author kyo@haiil2u.net
 */

PR['registerLangHandler'](
    PR['createSimpleLexer'](
        [
            // Whitespace
            [PR['PR_PLAIN'], /^[\t\n\r \xA0\u2028\u2029]+/, null, '\t\n\r \xA0\u2028\u2029']
        ],
        [
            // Double quoted string
            [PR['PR_STRING'], /^\"[^\"\r\n]*?\"/],
            // Single quoted string
            [PR['PR_STRING'], /^\'[^\'\r\n]*?\'/],
            // Line comment
            [PR['PR_COMMENT'], /^[\"\u2018\u2019][^\r\n\u2028\u2029]*/],
            // Keywords
            [PR['PR_KEYWORD'], /^(?:function|endfunction|delfunction|return|call|let|unlet|lockvar|unlockvar|if|endif|else|elseif|while|endwhile|for|in|endfor|continue|break|try|endtry|catch|finally|throw|echo|ehon|echohl|echomsg|echoerr|execute|set|autocmd|augroup|[nvxsoilc]?(?:nore)?map|command)\b/i],
            // Literal number
            [PR['PR_LITERAL'], /^(?:\d+)/i],
            // Identifier
            [PR['PR_PLAIN'], /^(?:(?:[a-z]|_\w)[\w\:]*)/i],
            // Punctuation
            [PR['PR_PUNCTUATION'], /^[^\s\w\'\"]+/]
        ]
    ),
    ['vim']
);
