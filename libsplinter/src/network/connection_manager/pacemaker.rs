// Copyright 2018-2020 Cargill Incorporated
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

use std::sync::{
    atomic::{AtomicBool, Ordering},
    mpsc::Sender,
    Arc,
};
use std::thread;
use std::time::Duration;

use crate::network::connection_manager::error::ConnectionManagerError;

pub struct Pacemaker {
    interval: u64,
    join_handle: Option<thread::JoinHandle<()>>,
    shutdown_signaler: Option<ShutdownSignaler>,
}

impl Pacemaker {
    pub fn new(interval: u64) -> Self {
        Self {
            interval,
            join_handle: None,
            shutdown_signaler: None,
        }
    }

    pub fn start<M, F>(
        &mut self,
        cm_sender: Sender<M>,
        new_message: F,
    ) -> Result<(), ConnectionManagerError>
    where
        M: Send + 'static,
        F: Fn() -> M + Send + 'static,
    {
        if self.join_handle.is_some() {
            return Ok(());
        }

        let running = Arc::new(AtomicBool::new(true));

        let running_clone = running.clone();
        let interval = self.interval;
        let join_handle = thread::Builder::new()
            .name("Heartbeat Monitor".into())
            .spawn(move || {
                info!("Starting heartbeat manager");

                while running_clone.load(Ordering::SeqCst) {
                    thread::sleep(Duration::from_secs(interval));
                    if let Err(err) = cm_sender.send(new_message()) {
                        error!(
                            "Connection manager has disconnected before
                            shutting down heartbeat monitor {:?}",
                            err
                        );
                        break;
                    }
                }
            })?;

        self.join_handle = Some(join_handle);
        self.shutdown_signaler = Some(ShutdownSignaler { running });

        Ok(())
    }

    pub fn shutdown_signaler(&self) -> Option<ShutdownSignaler> {
        self.shutdown_signaler.clone()
    }

    pub fn await_shutdown(self) {
        let join_handle = if let Some(jh) = self.join_handle {
            jh
        } else {
            return;
        };

        if let Err(err) = join_handle.join() {
            error!("Failed to shutdown heartbeat monitor gracefully: {:?}", err);
        }
    }
}

#[derive(Clone)]
pub struct ShutdownSignaler {
    running: Arc<AtomicBool>,
}

impl ShutdownSignaler {
    pub fn shutdown(&self) {
        self.running.store(false, Ordering::SeqCst)
    }
}
