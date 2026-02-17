import csv
import requests
import sys



def load_posts(input_path):
    pass



def get_top_posts(posts, limit=10):
    pass

def send_to_pipeline(post_content):
    """
    Send a post to the moderation service.
    Returns the hashtag string on success, or 'FAILED' if moderation fails.
    """
    pass 


def process_post(post, index):
    pass
    


def main():
    input_path = sys.argv[1] if len(sys.argv) > 1 else "input.csv"

    posts = load_posts(input_path)
    top_posts = get_top_posts(posts, limit=10)

    print(f"Processing {len(top_posts)} most-liked posts...\n")

    for i, post in enumerate(top_posts, start=1):
        process_post(post, i)


if __name__ == "__main__":
    main()
