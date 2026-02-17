import grpc
from concurrent import futures
import os

from google import genai

# import hashtagging_pb2
# import hashtagging_pb2_grpc

# Configure Gemini
client = genai.Client(api_key=os.environ["GOOGLE_API_KEY"])
MODEL = "gemini-2.0-flash"



def generate_hashtag(post_content):
    pass
    

class HashtagServiceServicer(hashtagging_pb2_grpc.HashtagServiceServicer):
    def GetHashtag(self, request, context):
        pass


def serve():
    pass
    


if __name__ == "__main__":
    serve()
