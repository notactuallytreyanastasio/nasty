let socket = new Phoenix.Socket("/socket")
socket.connect()

let channel = socket.channel("bookmark:feed", {})
channel.join()
  .receive("ok", resp => { console.log("Joined bookmark feed successfully", resp) })
  .receive("error", resp => { console.log("Unable to join bookmark feed", resp) })

// Listen for events
channel.on("bookmark:created", payload => {
  console.log("New bookmark created:", payload)
})

channel.on("bookmark:updated", payload => {
  console.log("Bookmark updated:", payload)
})

channel.on("bookmark:deleted", payload => {
  console.log("Bookmark deleted:", payload)
})