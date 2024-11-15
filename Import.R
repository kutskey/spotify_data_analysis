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


# 3. Overview of Categories --------------------------------------------------------------------------------------------------


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




# 3.1 Rock ------------------------------------------------------------------------------------------------------------

# Get the category id:
categories$id[categories$names=="Rock"] # 0JQ5DAqbMKFDXXwE9BDJAr
# categories %>% filter(names=="Rock") %>% select(id) %>% as.character()   # Same thing in dplyr

url_rock <- str_c("https://api.spotify.com/v1/browse/categories/", categories$id[categories$names=="Rock"],"/playlists")
params <- list(
    country = "CH",
    limit = 10
)

# Make the GET request
rock_r <- GET(url_rock, query = params, 
              add_headers("Authorization" = authorization_header))
rock <- content(rock_r, as = "parsed", encoding = "UTF-8")

# Get one playlist:
rock$playlists$items[[1]]
rock$playlists$items[[1]]$id

# Collect songs from Rock playlists
# https://developer.spotify.com/documentation/web-api/reference/get-playlist
url_plls <- str_c("https://api.spotify.com/v1/playlists/", rock$playlists$items[[1]]$id)
plls_r <- GET(url_plls, query = params, 
              add_headers("Authorization" = authorization_header))
plls <- content(plls_r, as = "parsed", encoding = "UTF-8")

# Get songs IDs:
id = plls$tracks$items[[1]]$track$id

# 4. Playlist --------------------------------------------------------------------------------

# Set up the endpoint and parameters
url_playlists <- str_c("https://api.spotify.com/v1/playlists/","6nHPZM0WZCG6p8dAE9G5vF")
params <- list(
    playlist_id = "6nHPZM0WZCG6p8dAE9G5vF"
)

# Make the GET request
response <- GET(url_playlists, 
                query = params, 
                add_headers("Authorization" = authorization_header))
playlist <- content(response, as = "parsed", encoding = "UTF-8")






# 5. Top Tracks of Artist X --------------------------------------------------------------------------------

# Set up the endpoint and parameters
url_toptracks <- str_c("https://api.spotify.com/v1/artists/","3AA28KZvwAUcZuOKwyblJQ","/top-tracks")
params <- list(
   market = "CH"
)

# Make the GET request
response <- GET(url_toptracks, 
                query = params, 
                add_headers("Authorization" = authorization_header))

toptracks <- content(response, as = "parsed", encoding = "UTF-8")


toptracks[["tracks"]][[1]][["artists"]][[1]][["name"]]
toptracks[["tracks"]][[1]][["name"]]
toptracks[["tracks"]][[1]][["href"]]


# Let's create a data frame `categories` extracting all the genres:
artists <- names <- hrefs <- vector(mode = "character", length = 10)
for (i in 1:10) {
    artists[i] <- toptracks[["tracks"]][[i]][["artists"]][[1]][["name"]]
    names[i] <- toptracks[["tracks"]][[i]][["name"]]
    hrefs[i] <- toptracks[["tracks"]][[i]][["href"]]
}
toptracks <- tibble(artists = artists, names = names, hrefs = hrefs)
toptracks

saveRDS(toptracks, "repo/Gorillaz_Top10.rds")



# 6. Genres -------------------------------------------------------------------------------------------------------



# Set up the endpoint and parameters
url_genres <- "https://api.spotify.com/v1/recommendations/available-genre-seeds"


# Make the GET request
response <- GET(url_genres, 
                
                add_headers("Authorization" = authorization_header))

# Process the response
genres <- content(response, as = "parsed", encoding = "UTF-8")


as.character(genres[1]$genres) # Genres for Recommendations

