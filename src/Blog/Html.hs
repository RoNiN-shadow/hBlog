module Blog.Html
  ( -- * HTML EDSL
    Html,
    html_,

    -- ** Combinators used to construct the @\<head\>@ section
    Head,
    title_,
    stylesheet_,
    meta_,

    -- ** Combinators used to construct the @\<body\>@ section
    Structure,
    p_,
    ul_,
    ol_,
    code_,
    h_,

    -- ** Combinators used to construct inside structures
    Content,
    txt_,
    img_,
    link_,
    b_,
    i_,

    -- ** Render HTML to String
    render,
  )
where

import Blog.Html.Internal
