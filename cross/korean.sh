function rnd-words-ko()
{
    rnd-words $WORDS_KO_FILE $1
}

function ko-count()
{
    echo {일,이,삼,사,오,육,질,팔,구} && echo -e {,이,삼,사,오,육,질,팔,구}십{,일,이,삼,사,오,육,질,팔,구"\n"}
}
