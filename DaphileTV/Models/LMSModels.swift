import Foundation

// MARK: - Artists

struct LMSArtistsResponse: Codable {
    let result: ArtistResult
}

struct ArtistResult: Codable {
    let artistsLoop: [LMSArtistItem]?
    let count: Int?

    enum CodingKeys: String, CodingKey {
        case artistsLoop = "artists_loop"
        case count
    }
}

struct LMSArtistItem: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let artworkUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name = "artist"
        case artworkUrl = "artwork_url"
    }

    var firstLetter: String {
        guard let firstChar = name.first else {
            return "#"
        }

        let letter = String(firstChar).uppercased()

        return letter.rangeOfCharacter(from: .letters) != nil
            ? letter
            : "#"
    }

    func pictureURL(serverIP: String) -> URL? {
        if let path = artworkUrl {
            if path.hasPrefix("http") {
                return URL(string: path)
            }

            return URL(string: "http://\(serverIP):9000/\(path)")
        }

        return URL(
            string: "http://\(serverIP):9000/imageproxy/mai/artist/\(id)/image.jpg"
        )
    }
}

// MARK: - Apps / Plugins

struct LMSAppsResponse: Codable {
    let result: AppsResult
}

struct AppsResult: Codable {
    let appsLoop: [LMSAppItem]?

    enum CodingKeys: String, CodingKey {
        case appsLoop = "apps_loop"
    }
}

struct LMSAppItem: Codable, Identifiable, Hashable {
    var id: String {
        cmd
    }

    let name: String
    let cmd: String
    let icon: String?

    func iconURL(serverIP: String) -> URL? {
        guard let iconPath = icon else {
            return nil
        }

        if iconPath.hasPrefix("http") {
            return URL(string: iconPath)
        }

        return URL(
            string: "http://\(serverIP):9000/\(iconPath)"
        )
    }
}

// MARK: - Player Status

struct LMSStatusResponse: Codable {
    let result: PlayerStatusResult
}

struct PlayerStatusResult: Codable {
    let currentTitle: String?
    let year: String?
    let time: Double?
    let playlistLoop: [LMSCurrentTrack]?

    enum CodingKeys: String, CodingKey {
        case currentTitle = "current_title"
        case year
        case time
        case playlistLoop = "playlist_loop"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        self.currentTitle = try? container.decode(
            String.self,
            forKey: .currentTitle
        )

        self.playlistLoop = try? container.decode(
            [LMSCurrentTrack].self,
            forKey: .playlistLoop
        )

        self.time = try? container.decode(
            Double.self,
            forKey: .time
        )

        if let stringYear = try? container.decode(
            String.self,
            forKey: .year
        ) {
            self.year = stringYear
        } else if let intYear = try? container.decode(
            Int.self,
            forKey: .year
        ) {
            self.year = String(intYear)
        } else {
            self.year = nil
        }
    }
}

struct LMSCurrentTrack: Codable {
    let title: String?
    let artist: String?
    let album: String?
    var year: String?
    let duration: Double?
    let artworkTrackID: String?

    enum CodingKeys: String, CodingKey {
        case title
        case artist
        case album
        case year
        case duration
        case artworkTrackID = "artwork_track_id"
    }
}

// MARK: - Tracks

struct LMSTracksResponse: Decodable {
    let result: TrackResult
}

struct TrackResult: Decodable {
    let titlesLoop: [LMSTrack]?

    enum CodingKeys: String, CodingKey {
        case titlesLoop = "titles_loop"
    }
}

struct LMSTrack: Decodable, Identifiable, Equatable {
    var id: String {
        if let numericID = trackid {
            return String(numericID)
        }

        return UUID().uuidString
    }

    let trackid: Int?
    let title: String
    let duration: Double?
    let tracknum: String?
    let fileType: String?
    let bitrate: String?
    let sampleRate: String?
    let sampleSize: String?

    enum CodingKeys: String, CodingKey {
        case trackid = "id"
        case title
        case duration
        case tracknum
        case fileType = "type"
        case bitrate
        case sampleRate = "samplerate"
        case sampleSize = "samplesize"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        self.trackid = try? container.decode(
            Int.self,
            forKey: .trackid
        )

        self.title = try container.decode(
            String.self,
            forKey: .title
        )

        if let floatDuration = try? container.decode(
            Double.self,
            forKey: .duration
        ) {
            self.duration = floatDuration
        } else if let stringDuration = try? container.decode(
            String.self,
            forKey: .duration
        ) {
            self.duration = Double(stringDuration)
        } else {
            self.duration = nil
        }

        if let stringNum = try? container.decode(
            String.self,
            forKey: .tracknum
        ) {
            self.tracknum = stringNum
        } else if let intNum = try? container.decode(
            Int.self,
            forKey: .tracknum
        ) {
            self.tracknum = String(intNum)
        } else {
            self.tracknum = nil
        }

        self.fileType = try? container.decode(
            String.self,
            forKey: .fileType
        )

        self.bitrate = try? container.decode(
            String.self,
            forKey: .bitrate
        )

        if let intBits = try? container.decode(
            Int.self,
            forKey: .sampleSize
        ) {
            self.sampleSize = "\(intBits)-bit"
        } else if let stringBits = try? container.decode(
            String.self,
            forKey: .sampleSize
        ) {
            self.sampleSize = "\(stringBits)-bit"
        } else {
            self.sampleSize = nil
        }

        if let stringSample = try? container.decode(
            String.self,
            forKey: .sampleRate
        ),
           let doubleString = Double(stringSample) {

            self.sampleRate = String(
                format: "%.1f kHz",
                doubleString / 1000.0
            )

        } else if let intSample = try? container.decode(
            Int.self,
            forKey: .sampleRate
        ) {

            self.sampleRate = String(
                format: "%.1f kHz",
                Double(intSample) / 1000.0
            )

        } else {
            self.sampleRate = nil
        }
    }
}

// MARK: - Albums

struct LMSResponse: Codable {
    let result: AlbumResult
}

struct AlbumResult: Codable {
    let albumsLoop: [LMSAlbum]?
    let count: Int?

    enum CodingKeys: String, CodingKey {
        case albumsLoop = "albums_loop"
        case count
    }
}

struct LMSAlbum: Codable, Identifiable, Equatable {
    let id: Int
    let title: String
    let artist: String
    let year: Int?
    let artworkTrackID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title = "album"
        case artist
        case year
        case artworkTrackID = "artwork_track_id"
    }

    func artworkURL(serverIP: String) -> URL? {
        let imageKey = artworkTrackID ?? String(id)

        return URL(
            string: "http://\(serverIP):9000/music/\(imageKey)/cover.jpg"
        )
    }
}

// MARK: - Players

struct LMSPlayersResponse: Codable {
    let result: PlayersResult?
}

struct PlayersResult: Codable {
    let playersLoop: [LMSPlayer]?

    enum CodingKeys: String, CodingKey {
        case playersLoop = "players_loop"
    }
}

struct LMSPlayer: Codable, Identifiable, Hashable {
    var id: String {
        playerid
    }

    let playerid: String
    let name: String
}

