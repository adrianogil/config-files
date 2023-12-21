
# config-tools rnd-words-ko: Get random korean words
function rnd-words-ko()
{
    rnd-words $WORDS_KO_FILE $1
}

# config-tools rnd-words-ko: Count 1 to 99 in korean
function ko-count()
{
    echo {일,이,삼,사,오,육,질,팔,구} && echo -e {,이,삼,사,오,육,질,팔,구}십{,일,이,삼,사,오,육,질,팔,구"\n"}
}
