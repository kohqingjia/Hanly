- LLM function is reall too slow, need to reduce time taken to generate. 
- Translate needs to produce better tags. preset tags need to be more robust?
- pinyin needs to be properly formatted to match the word below. 
- can refer to previous project (bytelingo)

future considerations:
- consider using docker
- use dictionary api for static easy search, llm function for more vague queries
- improve database logic on global dictionary rating, average score etc. how are these calculated? the rating should be suggestion rating, this is where users can rate the suggested word. then aggregate it to one row for the global one. i think average score is not needed.

note:
Redeployed with --no-verify-jwt. The function still verifies the user internally via authClient.auth.getUser(), so it's still secure — this just bypasses the infrastructure-level JWT check that was blocking the request before it reached your code.