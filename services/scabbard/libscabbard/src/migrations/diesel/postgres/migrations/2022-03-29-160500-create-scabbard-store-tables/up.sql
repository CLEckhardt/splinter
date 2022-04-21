-- Copyright 2018-2022 Cargill Incorporated
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- -----------------------------------------------------------------------------

CREATE TYPE coordinator_state AS ENUM ('WAITINGFORSTART', 'VOTING', 'WAITINGFORVOTE', 'ABORT', 'COMMIT');
CREATE TYPE coordinator_message_type AS ENUM ('VOTERESPONSE', 'DECISIONREQUEST');
CREATE TYPE coordinator_notification_type AS ENUM ('REQUESTFORSTART', 'COORDINATORREQUESTFORVOTE', 'COMMIT', 'ABORT', 'MESSAGEDROPPED');
CREATE TYPE participant_state AS ENUM ('WAITINGFORVOTEREQUEST', 'WAITINGFORVOTE', 'VOTED', 'ABORT', 'COMMIT');
CREATE TYPE participant_message_type AS ENUM ('VOTEREQUEST', 'COMMIT', 'ABORT', 'DECISIONREQUEST');
CREATE TYPE participant_notification_type AS ENUM ('PARTICIPANTREQUESTFORVOTE', 'COMMIT', 'ABORT', 'MESSAGEDROPPED');

CREATE TABLE IF NOT EXISTS consensus_coordinator_context (
    service_id                TEXT NOT NULL,
    alarm                     BIGINT,
    coordinator               TEXT NOT NULL,
    epoch                     BIGINT NOT NULL,
    last_commit_epoch         BIGINT,
    state                     coordinator_state NOT NULL,
    vote_timeout_start        BIGINT,
    PRIMARY KEY (service_id, epoch)
);

CREATE TABLE IF NOT EXISTS consensus_coordinator_context_participant (
    service_id                TEXT NOT NULL,
    epoch                     BIGINT NOT NULL,
    process                   TEXT NOT NULL,
    vote                      TEXT
    CHECK ( vote IN ('TRUE' , 'FALSE') OR vote IS NULL ),
    PRIMARY KEY (service_id, epoch, process),
    FOREIGN KEY (service_id, epoch) REFERENCES consensus_coordinator_context(service_id, epoch) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS consensus_action (
    id                        BIGSERIAL PRIMARY KEY,
    service_id                TEXT NOT NULL,
    epoch                     BIGINT NOT NULL,
    created_at                TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    executed_at               BIGINT,
    position                  INTEGER NOT NULL,
    FOREIGN KEY (service_id, epoch) REFERENCES consensus_coordinator_context(service_id, epoch) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS consensus_update_coordinator_context_action (
    action_id                 INTEGER PRIMARY KEY,
    service_id                TEXT NOT NULL,
    alarm                     BIGINT,
    coordinator               TEXT NOT NULL,
    epoch                     BIGINT NOT NULL,
    last_commit_epoch         BIGINT,
    state                     coordinator_state NOT NULL,
    vote_timeout_start        BIGINT,
    coordinator_action_alarm  BIGINT,
    FOREIGN KEY (action_id) REFERENCES consensus_action(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id, epoch) REFERENCES consensus_coordinator_context(service_id, epoch) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS consensus_coordinator_send_message_action (
    action_id                 INTEGER PRIMARY KEY,
    service_id                TEXT NOT NULL,
    epoch                     BIGINT NOT NULL,
    receiver_service_id       TEXT NOT NULL,
    message_type              coordinator_message_type NOT NULL,
    vote_response             TEXT
    CHECK ( (vote_response IN ('TRUE', 'FALSE')) OR (message_type != 'VOTERESPONSE') ),
    FOREIGN KEY (action_id) REFERENCES consensus_action(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id, epoch) REFERENCES consensus_coordinator_context(service_id, epoch) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS consensus_coordinator_notification_action (
    action_id                 INTEGER PRIMARY KEY,
    service_id                TEXT NOT NULL,
    epoch                     BIGINT NOT NULL,
    notification_type         coordinator_notification_type NOT NULL,
    dropped_message           TEXT
    CHECK ( (dropped_message IS NOT NULL) OR (notification_type != 'MESSAGEDROPPED') ),
    FOREIGN KEY (action_id) REFERENCES consensus_action(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id, epoch) REFERENCES consensus_coordinator_context(service_id, epoch) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS consensus_update_coordinator_context_action_participant (
    action_id                 INTEGER PRIMARY KEY,
    service_id                TEXT NOT NULL,
    epoch                     BIGINT NOT NULL,
    process                   TEXT NOT NULL,
    vote                      TEXT
    CHECK ( vote IN ('TRUE' , 'FALSE') OR vote IS NULL ),
    FOREIGN KEY (action_id) REFERENCES consensus_action(id) ON DELETE CASCADE,
    FOREIGN KEY (action_id) REFERENCES consensus_update_coordinator_context_action(action_id) ON DELETE CASCADE
);

-- participant tables ----------------------------------------------------------

CREATE TABLE IF NOT EXISTS consensus_participant_context (
    service_id                TEXT NOT NULL,
    alarm                     BIGINT,
    coordinator               TEXT NOT NULL,
    epoch                     BIGINT NOT NULL,
    last_commit_epoch         BIGINT,
    state                     participant_state NOT NULL,
    vote                      TEXT
    CHECK ( vote IN ('TRUE' , 'FALSE') OR vote IS NULL ),
    decision_timeout_start    BIGINT,
    PRIMARY KEY (service_id, epoch)
);

CREATE TABLE IF NOT EXISTS consensus_participant_context_participant (
    service_id                TEXT NOT NULL,
    epoch                     BIGINT NOT NULL,
    process                   TEXT NOT NULL,
    PRIMARY KEY (service_id, epoch, process),
    FOREIGN KEY (service_id, epoch) REFERENCES consensus_participant_context(service_id, epoch) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS consensus_update_participant_context_action (
    action_id                 INTEGER PRIMARY KEY,
    service_id                TEXT NOT NULL,
    alarm                     BIGINT,
    coordinator               TEXT NOT NULL,
    epoch                     BIGINT NOT NULL,
    last_commit_epoch         BIGINT,
    state                     participant_state NOT NULL,
    vote                      TEXT
    CHECK ( (vote IN ('TRUE' , 'FALSE')) OR (state != 'VOTED') ),
    decision_timeout_start    BIGINT,
    participant_action_alarm  BIGINT,
    FOREIGN KEY (action_id) REFERENCES consensus_action(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id, epoch) REFERENCES consensus_participant_context(service_id, epoch) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS consensus_update_participant_context_action_participant (
    action_id                 INTEGER PRIMARY KEY,
    service_id                TEXT NOT NULL,
    epoch                     BIGINT NOT NULL,
    process                   TEXT NOT NULL,
    FOREIGN KEY (action_id) REFERENCES consensus_update_participant_context_action(action_id) ON DELETE CASCADE,
    FOREIGN KEY (action_id) REFERENCES consensus_action(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS consensus_participant_send_message_action (
    action_id                 INTEGER PRIMARY KEY,
    service_id                TEXT NOT NULL,
    epoch                     BIGINT NOT NULL,
    receiver_service_id       TEXT NOT NULL,
    message_type              participant_message_type NOT NULL,
    vote_request              BYTEA
    CHECK ( (vote_request IS NOT NULL) OR (message_type != 'VOTEREQUEST') ),
    FOREIGN KEY (action_id) REFERENCES consensus_action(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id, epoch) REFERENCES consensus_participant_context(service_id, epoch) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS consensus_participant_notification_action (
    action_id                 INTEGER PRIMARY KEY,
    service_id                TEXT NOT NULL,
    epoch                     BIGINT NOT NULL,
    notification_type         participant_notification_type NOT NULL,
    dropped_message           TEXT
    CHECK ( (dropped_message IS NOT NULL) OR (notification_type != 'MESSAGEDROPPED') ),
    request_for_vote_value    BYTEA
    CHECK ( (request_for_vote_value IS NOT NULL) OR (notification_type != 'PARTICIPANTREQUESTFORVOTE') ),
    FOREIGN KEY (action_id) REFERENCES consensus_action(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id, epoch) REFERENCES consensus_participant_context(service_id, epoch) ON DELETE CASCADE
);