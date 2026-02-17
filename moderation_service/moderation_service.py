from fastapi import FastAPI
from pydantic import BaseModel
import grpc

# import hashtagging_pb2
# import hashtagging_pb2_grpc

app = FastAPI()

BANNED_WORDS = [
    # Fill this
]

class ModerateRequest(BaseModel):
    post_content: str


class ModerateResponse(BaseModel):
    result: str


def check_moderation(text):
    pass 


def get_hashtag_from_service(post_content):
    pass 


@app.post("/moderate")
def moderate(request):
    pass 
