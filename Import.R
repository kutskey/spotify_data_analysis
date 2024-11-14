# 1. Load Libraries -----------------------------------------------------------------------------------------------

library(tidyverse)
library(httr)
library(rvest)
library(readr)


# 2. Set up ------------------------------------------------------------------------------------------------


# Set up your credentials
spotify_cred <- read_delim("credentials.csv", 
                          delim = ";", escape_double = FALSE, trim_ws = TRUE)
client_id <- spotify_cred$client_id
client_secret <-  spotify_cred$client_secret

response <-  httr::POST(
    url = 'https://accounts.spotify.com/api/token',
    accept_json(),
    #  authenticate(user = client_id, password = client_secret),    # This would also be OK.
    body = list(grant_type = 'client_credentials',        # This is required, check doc
                client_id = client_id,                     # Credentials
                client_secret = client_secret, 
                content_type = "application/x-www-form-urlencoded"),   
    encode = 'form', 
    verbose()
)

# Extract content from the call and get access token as described in the docs:
content <- httr::content(response)
token <- content$access_token


authorization_header <- str_c(content$token_type, content$access_token, sep = " ")


# 3. Create a Tibble of Categories --------------------------------------------------------------------------------------------------


# Set up the endpoint and parameters
url_cats <- "https://api.spotify.com/v1/browse/categories"
params <- list(
    locale = "de_CH",
    limit = 10
)

# Make the GET request
response <- GET(url_cats, 
                query = params, 
                add_headers("Authorization" = authorization_header))

# Process the response
cats <- content(response, as = "parsed", encoding = "UTF-8")

cats[[1]]$items[[1]]$name    # name
cats[[1]]$items[[1]]$id      # id
cats[[1]]$items[[1]]$href    # url for the endpoint

# Let's create a data frame `categories` extracting all the genres:
ids <- names <- hrefs <- vector(mode = "character", length = 10)
for (i in 1:10) {
    ids[i] <- cats[[1]]$items[[i]]$id
    names[i] <- cats[[1]]$items[[i]]$name
    hrefs[i] <- cats[[1]]$items[[i]]$href
}
categories <- tibble(names = names, hrefs = hrefs, id = ids)
categories


# 4. Playlist --------------------------------------------------------------------------------

# Set up the endpoint and parameters
url_playlists <- "https://api.spotify.com/v1/playlists/{playlist_id}"
params <- list(
    playlist_id = "6nHPZM0WZCG6p8dAE9G5vF"
)

# Make the GET request
response <- GET(url_playlists, 
                query = params, 
                add_headers("Authorization" = authorization_header))




# 5. Top Tracks of Artist X --------------------------------------------------------------------------------

# Set up the endpoint and parameters
url_toptracks <- "https://api.spotify.com/v1/artists/{id}/top-tracks"
params <- list(
    id = "3AA28KZvwAUcZuOKwyblJQ"
)

# Make the GET request
response <- GET(url_toptracks, 
                query = params, 
                add_headers("Authorization" = authorization_header))

# 6. Genres -------------------------------------------------------------------------------------------------------



# Set up the endpoint and parameters
url_genres <- "https://api.spotify.com/v1/recommendations/available-genre-seeds"


# Make the GET request
response <- GET(url_genres, 
                
                add_headers("Authorization" = authorization_header))

# Process the response
genres <- content(response, as = "parsed", encoding = "UTF-8")


as.character(genres[1]$genres) # Genres for Recommendations

