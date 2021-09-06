<template>
  <div class="home">
    <div class="container">
      <div class="row">
        <div class="col-md-6 col-lg-6">
          <!-- 
                    Display video of the current user
                    Note: mute your own video, otherwise you'll hear yourself ...
                 -->
          <div class="text-center">
            <video
              id="my-camera"
              width="300"
              height="300"
              autoplay="autoplay"
              muted="true"
              class="center-block"
            ></video>
            <span class="label label-info">You</span>
          </div>
        </div>

        <div class="col-md-6 col-lg-6">
          <!-- Display video of the connected peer -->
          <div class="text-center">
            <video
              id="peer-camera"
              width="300"
              height="300"
              autoplay="autoplay"
              class="center-block"
            ></video>
            <span class="label label-info" id="connected_peer"></span>
          </div>
        </div>
      </div>

      <div class="row">
        <h1 class="text-center">
          vlcc common service
          <br />
          <small>
            Share the following ID with the person you want to connect</small
          >
        </h1>
        <!-- The ID of your current session -->
        <h4 class="text-center">
          <span id="peer-id-label"></span>
        </h4>
        <div class="col-md-12 col-lg-12">
          <div class="form-horizontal" id="connection-form">
            <fieldset>
              <legend>Connection Form</legend>
              <div class="form-group">
                <label for="name" class="col-lg-2 control-label"
                  >Username</label
                >
                <div class="col-lg-10">
                  <input
                    type="text"
                    class="form-control"
                    name="name"
                    id="name"
                    placeholder="Your random username"
                  />
                </div>
              </div>
              <div class="form-group">
                <label for="peer_id" class="col-lg-2 control-label"
                  >Peer ID (id of your friend)</label
                >
                <div class="col-lg-10">
                  <input
                    type="text"
                    class="form-control"
                    name="peer_id"
                    id="peer_id"
                    placeholder="Peer ID"
                    autocomplete="off"
                    autocorrect="off"
                    autocapitalize="off"
                    spellcheck="false"
                  />

                  <!-- Show message if someone connected to the client -->
                  <div id="connected_peer_container" class="hidden">
                    An user is already connected to your session. Just provide a
                    name to connect !
                  </div>
                </div>
              </div>
              <div class="form-group">
                <div class="col-lg-10 col-lg-offset-2">
                  <button id="connect-to-peer-btn" class="btn btn-primary">
                    Connect to Peer
                  </button>
                </div>
              </div>
            </fieldset>
          </div>
        </div>
        <div class="col-md-12 col-lg-12">
          <div id="chat" class="hidden">
            <div id="messages-container">
              <div class="list-group" id="messages"></div>
            </div>
            <div id="message-container">
              <div class="form-group">
                <label class="control-label">Live chat</label>
                <div class="input-group">
                  <span class="input-group-btn">
                    <button id="call" class="btn btn-info">Call</button>
                  </span>
                  <input
                    type="text"
                    class="form-control"
                    name="message"
                    id="message"
                    placeholder="Your messag here ..."
                  />
                  <span class="input-group-btn">
                    <button id="send-message" class="btn btn-success">
                      Send Message
                    </button>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
// @ is an alias to /src
// import * as peer from "../peer.min.js"
import Peer from "peerjs";
// import *  as Peer from "../peer.min.js"
export default {
  name: "Home",
  components: {},
  mounted: function () {
    var peer_id;
    var username;
    var conn;

    var peer = new Peer({
      host: "peerjs-server.herokuapp.com",
      secure: true,
      port: 443,
      // config: {
      //   iceServers: [
      //     { url: "stun:stun1.l.google.com:19302" },
      //     {
      //       url: "turn:numb.viagenie.ca",
      //       credential: "muazkh",
      //       username: "webrtc@live.com",
      //     },
      //   ],
      // },
    });
    console.log(peer);

    peer.on("open", function () {
      document.getElementById("peer-id-label").innerHTML = peer.id;
      console.log(peer.id);
    });

    peer.on("connection", function (connection) {
      conn = connection;
      peer_id = connection.peer;

      // Use the handleMessage to callback when a message comes in
      conn.on("data", handleMessage);

      // Hide peer_id field and set the incoming peer id as value
      document.getElementById("peer_id").className += " hidden";
      document.getElementById("peer_id").value = peer_id;
      document.getElementById("connected_peer").innerHTML =
        connection.metadata.username;
    });

    peer.on("error", function (err) {
      alert("An error ocurred with peer: " + err);
      console.error(err);
    });

    peer.on("call", function (call) {
      // Answer the call with your own video/audio stream
      call.answer(window.localStream);

      // Receive data
      call.on("stream", function (stream) {
        // Store a global reference of the other user stream
        window.peer_stream = stream;
        // Display the stream of the other user in the peer-camera video element !
        onReceiveStream(stream, "peer-camera");
      });

      // Handle when the call finishes
      call.on("close", function () {
        alert("The videocall has finished");
      });

      // use call.close() to finish a call
    });

    function requestLocalVideo(callbacks) {
      // Monkeypatch for crossbrowser geusermedia
      navigator.getUserMedia =
        navigator.getUserMedia ||
        navigator.webkitGetUserMedia ||
        navigator.mozGetUserMedia;

      // Request audio an video
      navigator.getUserMedia(
        { audio: true, video: true },
        callbacks.success,
        callbacks.error
      );
    }

    function onReceiveStream(stream, element_id) {
      // Retrieve the video element according to the desired
      var video = document.getElementById(element_id);
      // Set the given stream as the video source
      video.srcObject = stream;

      // Store a global reference of the stream
      window.peer_stream = stream;
    }

    function handleMessage(data) {
      var orientation = "text-left";

      // If the message is yours, set text to right !
      if (data.from == username) {
        orientation = "text-right";
      }

      var messageHTML =
        '<a href="javascript:void(0);" class="list-group-item' +
        orientation +
        '">';
      messageHTML +=
        '<h4 class="list-group-item-heading">' + data.from + "</h4>";
      messageHTML += '<p class="list-group-item-text">' + data.text + "</p>";
      messageHTML += "</a>";

      document.getElementById("messages").innerHTML += messageHTML;
    }

    document.getElementById("send-message").addEventListener(
      "click",
      function () {
        // Get the text to send
        var text = document.getElementById("message").value;

        // Prepare the data to send
        var data = {
          from: username,
          text: text,
        };

        // Send the message with Peer
        conn.send(data);

        // Handle the message on the UI
        handleMessage(data);

        document.getElementById("message").value = "";
      },
      false
    );

    document.getElementById("call").addEventListener(
      "click",
      function () {
        console.log("Calling to " + peer_id);
        console.log(peer);

        var call = peer.call(peer_id, window.localStream);

        call.on("stream", function (stream) {
          window.peer_stream = stream;

          onReceiveStream(stream, "peer-camera");
        });
      },
      false
    );

    document.getElementById("connect-to-peer-btn").addEventListener(
      "click",
      function () {
        username = document.getElementById("name").value;
        peer_id = document.getElementById("peer_id").value;

        if (peer_id) {
          conn = peer.connect(peer_id, {
            metadata: {
              username: username,
            },
          });

          conn.on("data", handleMessage);
        } else {
          alert("You need to provide a peer to connect with !");
          return false;
        }

        document.getElementById("chat").className = "";
        document.getElementById("connection-form").className += " hidden";
      },
      false
    );

    requestLocalVideo({
      success: function (stream) {
        window.localStream = stream;
        onReceiveStream(stream, "my-camera");
      },
      error: function (err) {
        alert("Cannot get access to your camera and video !");
        console.error(err);
      },
    });
  },
};
</script>
<style></style>
