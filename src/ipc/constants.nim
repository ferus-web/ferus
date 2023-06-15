#[
  A directory for constant magic-ish integers indicating stuff

  This code is licensed under the MIT license

  Authors:

  xTrayambak (xtrayambak at gmail dot com)
]#

const
  # Client/Server: IPC server's default port offset, changes depending on if the port is occupied
  # If yes, then the dynamic port selection is triggered.
  IPC_SERVER_DEFAULT_PORT* = 8080

  # Client->Server: sends this when it wants to handshake
  IPC_CLIENT_HANDSHAKE* = -65536

  # Server->All clients: shutting down
  IPC_SERVER_DYING* = -65535

  # Server->Client: wants this child to die 
  IPC_SERVER_REQUEST_TERMINATION* = -65533

  # Server->Client: accepted this child's handshake request, usually accompanied with
  # extra data
  IPC_SERVER_HANDSHAKE_ACCEPTED* = -65532

  # Client->Server: result of server's request
  IPC_CLIENT_RESULT* = -65531

  # Server->Client: handshake failed, no payload provided (pid, role, etc.)
  IPC_SERVER_HANDSHAKE_FAILED_EMPTY_PAYLOAD* = -65530

  # Server->Client: handshake failed, invalid role
  IPC_SERVER_HANDSHAKE_FAILED_INVALID_ROLE_KEY* = -65529

  # Server->Client: handshake failed, no broker affinity signature provided
  IPC_SERVER_HANDSHAKE_FAILED_NO_BROKER_AFFINITY* = -65528

  # Server->Client: handshake failed, role key is empty
  IPC_SERVER_HANDSHAKE_FAILED_EMPTY_ROLE_KEY* = -65527

  # Client->Server: request server for copy of DOM
  IPC_CLIENT_NEEDS_DOM* = -65526

  # Server->Client: request declined, unknown connection/not registered
  IPC_SERVER_REQUEST_DECLINE_NOT_REGISTERED* = -65525

  # Server/Client: the attached payload is a DOM, marshal it properly
  PACKET_TYPE_DOM* = -65524

  # Client: this client is dying
  IPC_CLIENT_SHUTDOWN* = -65523

  # Server->Client: Parse this HTML
  IPC_CLIENT_DO_HTML_PARSE* = -65522

  # Client->Server: result of HTML parsing
  IPC_CLIENT_RESULT_HTML_PARSE* = -65521