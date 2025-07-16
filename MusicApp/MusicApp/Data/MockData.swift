import Foundation

struct MockData {
    static let tracks: [Track] = [
        Track(
            title: "Midnight Dreams",
            artist: "Alex Chen",
            avatar: "AC",
            genre: "Lo-Fi",
            duration: "2:34",
            likes: 234,
            collaborators: 3,
            isOpen: false,
            type: .track,
            description: nil
        ),
        Track(
            title: "Punchy Drum Loop",
            artist: "beatmaker_sam",
            avatar: "BS",
            genre: "Hip-Hop",
            duration: "0:16",
            likes: 89,
            collaborators: 0,
            isOpen: true,
            type: .stem,
            description: "Need someone to add melody and bass to this groove"
        ),
        Track(
            title: "Finish My Synthwave Track",
            artist: "RetroWave Studios",
            avatar: "RW",
            genre: "Synthwave",
            duration: "1:45",
            likes: 156,
            collaborators: 2,
            isOpen: true,
            type: .collaboration,
            description: "Looking for a vocalist to complete this 80s-inspired track"
        ),
        Track(
            title: "Ocean Waves",
            artist: "Luna Martinez",
            avatar: "LM",
            genre: "Ambient",
            duration: "3:12",
            likes: 445,
            collaborators: 1,
            isOpen: false,
            type: .track,
            description: nil
        ),
        Track(
            title: "Smooth Jazz Bass",
            artist: "JazzCat",
            avatar: "JC",
            genre: "Jazz",
            duration: "0:32",
            likes: 67,
            collaborators: 0,
            isOpen: true,
            type: .stem,
            description: "Perfect foundation for a chill jazz track"
        ),
        Track(
            title: "Electric Summer",
            artist: "DJ Voltage",
            avatar: "DV",
            genre: "Electronic",
            duration: "3:45",
            likes: 892,
            collaborators: 4,
            isOpen: false,
            type: .track,
            description: nil
        ),
        Track(
            title: "Trap Beat Foundation",
            artist: "808 Master",
            avatar: "8M",
            genre: "Trap",
            duration: "0:24",
            likes: 156,
            collaborators: 0,
            isOpen: true,
            type: .stem,
            description: "Hard-hitting 808s ready for your melody"
        ),
        Track(
            title: "Need a Guitar Solo",
            artist: "Rock Revival",
            avatar: "RR",
            genre: "Rock",
            duration: "2:15",
            likes: 234,
            collaborators: 1,
            isOpen: true,
            type: .collaboration,
            description: "Classic rock track missing that epic guitar solo"
        )
    ]
}
