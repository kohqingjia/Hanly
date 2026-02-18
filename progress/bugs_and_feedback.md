- LLM function is really too slow, especially for onboarding suggestion. need to reduce time taken to generate. 
- flashcard UI looks abyssmal 


future considerations:
- consider using docker
- use dictionary api for static easy search, llm function for more vague queries
- improve database logic on global dictionary rating, average score etc. how are these calculated? the rating should be suggestion rating, this is where users can rate the suggested word. then aggregate it to one row for the global one. i think average score is not needed.
- maybe remove the tags for each word. find a better way to do suggestions, maybe we just base on similar users? 
- i want all the characters in the dictionary to be able to be clikable and search

note:
Redeployed with --no-verify-jwt. The function still verifies the user internally via authClient.auth.getUser(), so it's still secure — this just bypasses the infrastructure-level JWT check that was blocking the request before it reached your code.
