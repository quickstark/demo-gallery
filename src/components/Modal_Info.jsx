import { FiMessageCircle, FiTrash2, FiAlertTriangle } from "react-icons/fi";
import {
  Link,
  Dialog,
  Button,
  DialogBody,
  DialogCloseTrigger,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogBackdrop,
  DialogRoot,
  Text,
  VStack,
} from "@chakra-ui/react";

import React from "react";

export default function Modal_Info({ isOpen, onOpen, onClose }) {
  return (
    <DialogRoot open={isOpen} onOpenChange={({ open }) => !open && onClose()}>
      <DialogBackdrop />
      <DialogContent>
        <DialogHeader>What is this supposed to be anyway?</DialogHeader>
        <DialogCloseTrigger />
        <DialogBody>
          <Text fontSize="lg">
            This site was built using<br></br>
            <Link href="https://github.com/" isExternal>
              Github
            </Link>
            ,{" "}
            <Link href="https://railway.app/" isExternal>
              Railway
            </Link>
            ,{" "}
            <Link href="https://vitejs.dev/" isExternal>
              Vite
            </Link>
            ,{" "}
            <Link href="https://fastapi.tiangolo.com/" isExternal>
              FastAPI
            </Link>
            ,{" "}
            <Link href="https://www.postgresql.org/" isExternal>
              Postgres
            </Link>
          </Text>
          <br></br>
          <VStack spacing={4} align="left">
            <Text fontSize="lg">
              Vite & FastAPI have been instrumented Error Monitoring
              and Performance Monitoring.
            </Text>
            <Text>1. Upload a picture.</Text>
            <Text>
              2. If your pic contains the word "Error" or "Errors", the FASTApi
              integration will issue an error.
            </Text>
            <Text>3. Then try clicking a button</Text>
            <Text>
              <FiAlertTriangle style={{display: 'inline'}} />
              {" - "}
              button to send an Error with your Image Name and Labels.
            </Text>
            <Text>
              <FiMessageCircle style={{display: 'inline'}} />
              {" - "}
              button to trap an Unhandled Error with Feedback.
            </Text>
            <Text>
              <FiTrash2 style={{display: 'inline'}} />
              {" - "}
              button to delete a picture.
            </Text>
          </VStack>
        </DialogBody>

        <DialogFooter>
          <Button colorScheme="yellow" mr={3} onClick={onClose}>
            Close
          </Button>
        </DialogFooter>
      </DialogContent>
    </DialogRoot>
  );
}
