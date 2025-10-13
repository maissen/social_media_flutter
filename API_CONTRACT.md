# Social Media API Contract v1.0

## Base URL
```
Production: https://api.yoursocialapp.com/v1
Development: http://localhost:8000/v1
```

---

## 1. Authentication & Authorization

### 1.1 Register User
**POST** `/auth/register`

**Request Body:**
```json
{
  "email": "user@example.com",
  "username": "johndoe",
  "password": "SecurePass123!",
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": null,
  "message": "User registered successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `error`
```json
  {
    "success": false,
    "message": "Failed ",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```

### 1.2 Login
**POST** `/auth/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 3600,
    "user": {
      "user_id": "3",
      "email": "user@example.com",
      "username": "johndoe",
      "profile_picture": "https://storage.com/profile.jpg"
    }
  },
  "message": "Login successful",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `error`
```json
  {
    "success": false,
    "message": "Failed ",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```
---

### 1.4 Logout
**POST** `/auth/logout`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": null,
  "message": "Logged out successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `error`
```json
  {
    "success": false,
    "message": "Failed ",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```
---

## 2. User Management

### 2.1 Get User Profile
**GET** `/users/profile/<user-id>`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "user_id": "v4",
    "email": "user@example.com",
    "username": "johndoe",
    "bio": "Software developer and tech enthusiast",
    "profile_picture": "https://storage.com/profile.jpg",
    "followers_count": 150,
    "following_count": 200,
    "posts_count": 45,
    "created_at": "2025-01-15T10:30:00Z",
    "is_following": false
  },
  "message": "User profile retrieved successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `error`
```json
  {
    "success": false,
    "message": "Failed ",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```
---

### 2.2 Update User Profile
#### update profile bio
**PUT** `/users/update/bio`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "new_bio": "Updated bio"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "new_bio": "Updated bio"
  },
  "message": "Bio updated successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `error`
```json
  {
    "success": false,
    "message": "Failed ",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```

#### update profile picture
**PUT** `/users/update-profile-picture`

**Headers:** `Authorization: Bearer <token>`

**Request Body (multipart/form-data):**

| Field | Type | Description |
|-------|------|-------------|
| file  | file | The image file to upload as the profile picture |

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "file_url": "https://storage.com/profile.jpg"
  },
  "message": "Profile picture updated successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `error`
```json
  {
    "success": false,
    "message": "Failed ",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```

---

### 2.4 Search Users
**GET** /users/search?username=maissen

**Query Parameters:**
- `username` (required): searched username

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "user_id": "v4",
      "email": "user@example.com",
      "username": "johndoe",
      "bio": "Software developer and tech enthusiast",
      "profile_picture": "https://storage.com/profile.jpg",
      "followers_count": 150,
      "following_count": 200,
      "posts_count": 45,
      "created_at": "2025-01-15T10:30:00Z",
      "is_following": false
    }
  ],
  "message": "Users retrieved successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `error`
```json
  {
    "success": false,
    "message": "Failed ",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```
---

## 3. Social Features

### 3.1 Follow User
**POST** `/users/follow-unfollow/?target_user_id=3`

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `target_user_id` (required): the target_user_id to follow/unfollow

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "is_following": true/false
  },
  "message": "User followed/unfollowed successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `error`
```json
  {
    "success": false,
    "message": "Failed ",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```
---

### 3.3 Get Followers
**GET** `/users/followers?user_id=3`

**Query Parameters:**
- `user_id` (required): the user_id to follow or unfollow

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "user_id": "v4",
      "email": "user@example.com",
      "username": "johndoe",
      "bio": "Software developer and tech enthusiast",
      "profile_picture": "https://storage.com/profile.jpg",
      "followers_count": 150,
      "following_count": 200,
      "posts_count": 45,
      "created_at": "2025-01-15T10:30:00Z",
      "is_following": false
    }
  ],
  "message": "Followers retrieved successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `error`
```json
  {
    "success": false,
    "message": "Failed ",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```
---

### 3.4 Get Following
**GET** `/users/followings?user_id=3`

**Query Parameters:**
- `user_id` (required): the user_id to follow/unfollow

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "user_id": "v4",
      "email": "user@example.com",
      "username": "johndoe",
      "bio": "Software developer and tech enthusiast",
      "profile_picture": "https://storage.com/profile.jpg",
      "followers_count": 150,
      "following_count": 200,
      "posts_count": 45,
      "created_at": "2025-01-15T10:30:00Z",
      "is_following": false
    }
  ],
  "message": "Following list retrieved successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `error`
```json
  {
    "success": false,
    "message": "Failed to fetch followings list",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```
---

## 4. Posts

### 4.1 Create a Post
**POST** `/posts/create`

**Headers:** 
- `Authorization: Bearer <token>`
- `Content-Type: multipart/form-data` (for media uploads)

**Request Body (multipart/form-data):**

| Field      | Type        | Description                                    |
|------------|------------|------------------------------------------------|
| content    | string     | Text content of the post (optional if media_file is provided) |
| media_file | file       | Optional media file to upload (image/video)   |

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "post_id": 7,
    "user_id": 4,
    "content": "hello world",
    "media_url": "http://something.com/image.jpg",
    "created_at": "2025-10-06T10:30:00Z",
    "likes_nbr": 0,
    "comments_nbr": 0,
    "is_liked_by_me": false
  },
  "message": "Post created successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `error`
```json
  {
    "success": false,
    "message": "Failed to create post",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```
---

### 4.2 Get Posts of a user
**GET** `/posts/<user-id>`

**Headers:** 
- `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "post_id": 7,
      "user_id": 1,
      "content": "This is my post content",
      "media_url": "https://storage.com/image1.jpg",
      "created_at": "2025-10-06T10:30:00Z",
      "likes_nbr": 42,
      "comments_nbr": 15,
      "is_liked_by_me": false,
    }
  ],
  "message": "Post retrieved successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `error`
```json
  {
    "success": false,
    "message": "Failed to retrieve posts",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```
---

### 4.5 Update Post
**PUT** `/posts/update/<post-id>`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "new_content": "new content",
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "new_content": "Updated content",
  },
  "message": "Post updated successfully",
  "timestamp": "2025-10-06T10:35:00Z"
}
```

**Response:** `error`
```json
  {
    "success": false,
    "message": "Failed ",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```
---

### 4.6 Delete Post
**DELETE** `/posts/delete/<post-id>`

**Headers:** `Authorization: Bearer <token>`

**Response:** `success`
```json
  {
    "success": true,
    "message": "post deleted successfully",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```

---

### 4.7 Like Post
**POST** `/posts/like-deslike/<post-id>`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
      "post_id": 7,
      "user_id": 1,
      "content": "This is my post content",
      "media_url": "https://storage.com/image1.jpg",
      "created_at": "2025-10-06T10:30:00Z",
      "likes_nbr": 42,
      "comments_nbr": 15,
      "is_liked_by_me": false/false,
    },
  "message": "Post liked/desliked successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `error`
```json
  {
    "success": false,
    "message": "Failed ",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```
---

### 4.8 Get Likes of a Post
**GET** `/posts/likes?post_id=1`

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `post_id` (required): ID of the post to retrieve likes for

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "user_id": 7,
      "email": "user@example.com",
      "username": "johndoe",
      "profile_picture": "https://storage.com/profile.jpg",
      "is_following": false
    }
  ],
  "message": "likes fetched successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `404 Not Found`
```json
{
  "success": false,
  "message": "Post not found",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `500 Internal Server Error`
```json
{
  "success": false,
  "message": "Failed to retrieve likes of post",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

---

## 5. Comments

### 5.1 Create Comment
**POST** `/posts/comments/create?post_id=1`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "content": "Great post!",
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": null,
  "message": "Comment created successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `error`
```json
  {
    "success": false,
    "message": "Failed ",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```
---

### 5.2 Get Comments of a post
**GET** `/posts/comments/all?post_id=1`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "comment_id": 1,
      "post_id": 1,
      "user_id": 4,
      "username": "johndoe",
      "profile_picture": "https://storage.com/profile.jpg",
      "comment_payload": "Great post!",
      "created_at": "2025-10-06T10:30:00Z",
      "likes_nbr": 5,
      "is_liked_by_me": false,
      "user": {
        "user_id": 1,
        "email": "x@gmail.com",
        "username": "Fadi",
        "profile_picture": "",
        "is_following": "false",
      }
    }
  ],
  "message": "Comments retrieved successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `error`
```json
  {
    "success": false,
    "message": "Failed ",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```
---

### 5.3 Delete Comment
**DELETE** `posts/comments/delete?comment_id=1?post_id=3`

**Headers:** `Authorization: Bearer <token>`

**Response:** `204 No Content`

---

### 5.4 Like Comment
**POST** `posts/comments/like-deslike/<comment-id>`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
      "comment_id": 2,
      "post_id": 1,
      "user_id": 5,
      "username": "janedoe",
      "profile_picture": "https://storage.com/profile2.jpg",
      "comment_payload": "Nice post!",
      "created_at": "2025-10-06T10:32:00Z",
      "likes_nbr": 2,
      "is_liked_by_me": true
    },
  "message": "Comment liked successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```

**Response:** `error`
```json
  {
    "success": false,
    "message": "Failed ",
    "timestamp": "2025-10-06T10:30:00Z"
  }
```
---

### 5.4 User's feed
**GET** `feed/`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "post_id": 7,
      "user_id": 1,
      "content": "This is my post content",
      "media_url": "",
      "created_at": "2025-10-06T10:30:00Z",
      "likes_nbr": 42,
      "comments_nbr": 15,
      "is_liked_by_me": false,
    }
  ],
  "message": "Comment liked successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```


### 5.5 Explore Feed
**GET** `feed/explore`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data" : [
    {
      "post_id": 7,
      "user_id": 1,
      "content": "This is my post content",
      "media_url": "https://storage.com/image1.jpg",
      "created_at": "2025-10-06T10:30:00Z",
      "likes_nbr": 42,
      "comments_nbr": 15,
      "is_liked_by_me": false,
    },
    {
      "post_id": 7,
      "user_id": 1,
      "content": "This is my post content",
      "media_url": "https://storage.com/image1.jpg",
      "created_at": "2025-10-06T10:30:00Z",
      "likes_nbr": 42,
      "comments_nbr": 15,
      "is_liked_by_me": false,
    }
  ],
  "message": "Comment liked successfully",
  "timestamp": "2025-10-06T10:30:00Z"
}
```
