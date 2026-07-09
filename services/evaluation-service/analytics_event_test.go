package main

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
)

type fakeEventPublisher struct {
	content string
	err     error
}

func (f *fakeEventPublisher) Publish(_ context.Context, content string) error {
	f.content = content
	return f.err
}

func TestSendEvaluationEventPublishesOCICompatiblePayload(t *testing.T) {
	publisher := &fakeEventPublisher{}
	app := &App{EventPublisher: publisher}

	app.sendEvaluationEvent("user-123", "new-checkout", true)

	var event EvaluationEvent
	if err := json.Unmarshal([]byte(publisher.content), &event); err != nil {
		t.Fatalf("payload inválido: %v", err)
	}
	if event.UserID != "user-123" || event.FlagName != "new-checkout" || !event.Result {
		t.Fatalf("evento inesperado: %+v", event)
	}
	if event.Timestamp.IsZero() {
		t.Fatal("timestamp deve ser preenchido")
	}
}

func TestSendEvaluationEventDoesNotPanicWhenPublishFails(t *testing.T) {
	app := &App{EventPublisher: &fakeEventPublisher{err: errors.New("queue unavailable")}}
	app.sendEvaluationEvent("user-123", "new-checkout", false)
}

func TestPublisherIsDisabledWithoutQueueOCID(t *testing.T) {
	t.Setenv("OCI_QUEUE_OCID", "")

	publisher, err := newAnalyticsEventPublisherFromEnv()
	if err != nil {
		t.Fatalf("erro inesperado: %v", err)
	}
	if publisher != nil {
		t.Fatal("publisher deveria estar desabilitado")
	}
}

func TestPublisherRequiresMessagesEndpoint(t *testing.T) {
	t.Setenv("OCI_QUEUE_OCID", "ocid1.queue.example")
	t.Setenv("OCI_QUEUE_MESSAGES_ENDPOINT", "")

	_, err := newAnalyticsEventPublisherFromEnv()
	if err == nil {
		t.Fatal("esperava erro de configuração incompleta")
	}
}
