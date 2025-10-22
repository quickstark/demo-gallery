import { FiMessageCircle, FiTrash2, FiAlertTriangle } from "react-icons/fi";
import {
  Heading,
  Separator,
  Center,
  Link,
  List,
  ListItem,
  Text,
  VStack,
  Container,
} from "@chakra-ui/react";
import React from "react";
import { useEffect } from "react";

export default function About() {
  useEffect(() => {
    // Component mounted - analytics tracked via RUM
  }, []);
  return (
    <Center fontSize="1.2em">
      <VStack width="lg" spacing={4} align="left">
        <Container bg="gray.700" borderRadius={10} padding={5}>
          <Heading size="lg" mb={3}>This site was built using</Heading>
          <Text fontSize="1.2em">
            <Link color="pink.500" href="https://github.com/" isExternal>
              Github
            </Link>
            ,{" "}
            <Link color="pink.500" href="https://railway.app/" isExternal>
              Railway
            </Link>
            ,{" "}
            <Link color="pink.500" href="https://vitejs.dev/" isExternal>
              Vite
            </Link>
            ,{" "}
            <Link
              color="pink.500"
              href="https://fastapi.tiangolo.com/"
              isExternal
            >
              FastAPI
            </Link>
            ,{" "}
            <Link
              color="pink.500"
              href="https://www.postgresql.org/"
              isExternal
            >
              Postgres
            </Link>
            ,{" "}
            <Link
              color="pink.500"
              href="https://aws.amazon.com/rekognition/"
              isExternal
            >
              Amazon Rekognition
            </Link>
            ... and{" "}
            <Link color="pink.500" href="https://datadoghq.com" isExternal>
              Datadog
            </Link>
            , of course
          </Text>
        </Container>
        <Container bg="pink.800" borderRadius={10} padding={5}>
          <Heading size="lg">What's been instrumented?</Heading>
          <Text fontSize="lg">
            Vite & FastAPI have been instrumented with Error Monitoring
            and Performance Monitoring.
          </Text>
        </Container>
        <Container bg="gray.700" borderRadius={10} padding={5} fontSize="1.2em">
          <Heading size="lg">Quick Instructions</Heading>
          <List.Root as="ol" styleType="decimal">
            <ListItem>Upload a picture.</ListItem>
            <ListItem>
              If your pic contains the word "Error" or "Errors" or contains an
              image identified as a "Bug", the FASTApi integration will issue an
              error.
            </ListItem>
            <ListItem>Then try clicking a button</ListItem>
            <Separator margin={5} size="md" />
          </List.Root>
          <Text>
            <FiAlertTriangle color="yellow.500" style={{display: 'inline'}} />
            {" - "}
            sends an Error with your Image Name + Labels.
          </Text>
          <Text>
            <FiMessageCircle color="yellow.500" style={{display: 'inline'}} />
            {" - "}
            traps an Unhandled Error with Feedback.
          </Text>
          <Text>
            <FiTrash2 color="red.500" style={{display: 'inline'}} />
            {" - "}
            deletes a picture.
          </Text>
        </Container>
      </VStack>
    </Center>
  );
}
